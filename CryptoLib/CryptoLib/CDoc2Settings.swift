//
//  CryptoDataFile.swift
//  CryptoLib
/*
 * Copyright 2017 - 2024 Riigi Infosüsteemi Amet
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

import Foundation

public class CDoc2Settings: NSObject {
    public static let kUseCDoc2Encryption = "kUseCDoc2Encryption"
    public static let kUseCDoc2OnlineEncryption = "kUseCDoc2OnlineEncryption"
    public static let kCDoc2SelectedService = "kCDoc2SelectedService"
    public static let kCDoc2UUID = "kCDoc2UUID"
    public static let kCDoc2PostURL = "kCDoc2PostURL"
    public static let kCDoc2FetchURL = "kCDoc2FetchURL"
    public static let kCDoc2Cert = "kCDoc2Cert"
    @objc public static let kProxyHost = "kProxyHost"
    @objc public static let kProxyPort = "kProxyPort"
    @objc public static let kProxyUsername = "kProxyUsername"
    @objc public static let kProxyPassword = "kProxyPassword"

    private static func set<T>(_ key: String, value: T) {
        UserDefaults.standard.set(value, forKey: key)
    }

    private static func get<T>(_ key: String) -> T? {
        return UserDefaults.standard.object(forKey: key) as? T
    }

    public class var useEncryption: Bool {
        get { get(kUseCDoc2Encryption) ?? false }
        set { set(kUseCDoc2Encryption, value: newValue) }
    }

    public class var useOnlineEncryption: Bool {
        get { get(kUseCDoc2OnlineEncryption) ?? true }
        set { set(kUseCDoc2OnlineEncryption, value: newValue) }
    }

    public class var cdoc2SelectedService: String? {
        get { get(kCDoc2SelectedService) }
        set { set(kCDoc2SelectedService, value: newValue) }
    }

    public class var cdoc2UUID: String? {
        get { get(kCDoc2UUID) }
        set { set(kCDoc2UUID, value: newValue) }
    }

    public class var cdoc2PostURL: String? {
        get { get(kCDoc2PostURL) }
        set { set(kCDoc2PostURL, value: newValue) }
    }

    public class var cdoc2FetchURL: String? {
        get { get(kCDoc2FetchURL) }
        set { set(kCDoc2FetchURL, value: newValue) }
    }

    public class var cdoc2Cert: Data? {
        get { get(kCDoc2Cert) }
        set { set(kCDoc2Cert, value: newValue) }
    }

    @objc public static var cdoc2Certs = [Data]()

    @objc public class func isEncryptionEnabled() -> Bool {
        return useEncryption
    }

    @objc public class func isOnlineEncryptionEnabled() -> Bool {
        return useOnlineEncryption
    }

    @objc public class func getSelectedService() -> String? {
        return cdoc2SelectedService
    }

    @objc public class func getUUID() -> String? {
        return cdoc2UUID
    }

    @objc public class func getPostURL() -> String? {
        return cdoc2PostURL
    }

    @objc public class func getFetchURL() -> String? {
        return cdoc2FetchURL
    }

    @objc public class func getCert() -> Data? {
        return cdoc2Cert
    }

    private static func findProxy(withData data: Bool = false) -> [String: Any]? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassInternetPassword,
            kSecAttrLabel: "proxy",
            kSecReturnAttributes: true,
            kSecReturnData: (data ? kCFBooleanTrue! : kCFBooleanFalse!),
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        switch SecItemCopyMatching(query as CFDictionary, &item) {
        case errSecSuccess:
            return item as? [String: Any]
        case errSecItemNotFound:
            return nil
        case (let status):
            print("Keychain lookup failed \(status).")
        }
        return nil
    }

    @objc public class func proxyCredentials() -> [String: Any]? {
        guard let result = findProxy(withData: true),
              let host = result[kSecAttrServer as String] as? String,
              let port = result[kSecAttrPort as String] as? Int,
              let username = result[kSecAttrAccount as String] as? String,
              let passwordData = result[kSecValueData as String] as? Data,
              let password = String(data: passwordData, encoding: .utf8) else {
            return nil
        }
        return [
            kProxyHost: host,
            kProxyPort: port,
            kProxyUsername: username,
            kProxyPassword: password
        ]
    }

    public class func setProxyCredentials(host: String, port: Int, username: String, password: String) {
        let passwordData = password.data(using: .utf8)!
        if let existing = findProxy() {
            let updateQuery: [CFString: Any] = [
                kSecClass: kSecClassInternetPassword,
                kSecAttrLabel: "proxy",
                kSecAttrServer: existing[kSecAttrServer as String]!,
                kSecAttrPort: existing[kSecAttrPort as String]!,
                kSecAttrAccount: existing[kSecAttrAccount as String]!
            ]

            let updateAttrs: [CFString : Any] = [
                kSecAttrLabel: "proxy",
                kSecAttrServer: host,
                kSecAttrPort: port,
                kSecAttrAccount: username,
                kSecValueData: passwordData
            ]

            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttrs as CFDictionary)
            if updateStatus != errSecSuccess {
                print("Keychain update failed: \(updateStatus)")
            }
        } else {
            let attributes: [CFString : Any] = [
                kSecClass: kSecClassInternetPassword,
                kSecAttrLabel: "proxy",
                kSecAttrServer: host,
                kSecAttrPort: port,
                kSecAttrAccount: username,
                kSecValueData: passwordData
            ]

            let addStatus = SecItemAdd(attributes as CFDictionary, nil)
            if addStatus != errSecSuccess {
                print("Keychain add failed: \(addStatus)")
            }
        }
    }

    public class func clearProxyCredentials() {
        if let item = findProxy() {
            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassInternetPassword,
                kSecAttrServer as String: item[kSecAttrServer as String]!,
                kSecAttrPort as String:  item[kSecAttrPort as String]!,
                kSecAttrAccount as String:  item[kSecAttrAccount as String]!
            ]
            let deleteStatus = SecItemDelete(deleteQuery as CFDictionary)
            if deleteStatus != errSecSuccess {
                print("Keychain delete failed: \(deleteStatus)")
            }
        }
    }
}
