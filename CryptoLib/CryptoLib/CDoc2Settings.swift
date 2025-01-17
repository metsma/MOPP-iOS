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
    public static let kUseCDoc2SelectedService = "kUseCDoc2SelectedService"
    public static let kUseCDoc2UUID = "kUseCDoc2UUID"
    public static let kUseCDoc2PostURL = "kUseCDoc2PostURL"
    public static let kUseCDoc2FetchURL = "kUseCDoc2FetchURL"
    public static let kUseCDoc2Cert = "kUseCDoc2Cert"

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
        get { get(kUseCDoc2SelectedService) }
        set { set(kUseCDoc2SelectedService, value: newValue) }
    }

    public class var cdoc2UUID: String? {
        get { get(kUseCDoc2UUID) }
        set { set(kUseCDoc2UUID, value: newValue) }
    }

    public class var cdoc2PostURL: String? {
        get { get(kUseCDoc2PostURL) }
        set { set(kUseCDoc2PostURL, value: newValue) }
    }

    public class var cdoc2FetchURL: String? {
        get { get(kUseCDoc2FetchURL) }
        set { set(kUseCDoc2FetchURL, value: newValue) }
    }

    public class var cdoc2Cert: Data? {
        get { get(kUseCDoc2Cert) }
        set { set(kUseCDoc2Cert, value: newValue) }
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
}
