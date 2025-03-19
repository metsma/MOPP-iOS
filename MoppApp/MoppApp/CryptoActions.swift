//
//  CryptoActions.swift
//  MoppApp
//
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

import MoppUI
import SwiftUI

protocol CryptoActions {
    func startEncryptingProcess()
    func startDecryptingProcess()
}

extension CryptoActions where Self: CryptoContainerViewController {
    @MainActor
    private func encrypted() {
        self.isCreated = false
        self.isForPreview = false
        self.isDecrypted = false
        self.state = .loading
        self.containerViewDelegate.openContainer(afterSignatureCreated: true)
        UIAccessibility.post(notification: .screenChanged, argument: L(.cryptoEncryptionSuccess))
        let encryptionSuccess = NotificationMessage(isSuccess: true, text: L(.cryptoEncryptionSuccess))
        if !self.notifications.contains(where: { $0 == encryptionSuccess }) {
            self.notifications.append(encryptionSuccess)
        }
        MoppFileManager.removeFiles()
    }

    func startEncryptingProcess() {
        guard container.addressees.count > 0 else {
            return self.infoAlert(message: L(.cryptoNoAddresseesWarning))
        }
        guard let container else { return }
        Task { [weak self] in
            do {
                try await Encrypt.encryptFile(container.filePath, with: container.dataFiles, with: container.addressees)
                await self?.encrypted()
            } catch {
                await self?.infoAlert(message: L(.cryptoEncryptionErrorText))
            }
        }
    }
    func startEncryptingLongTermProcess() {
        let swiftUIView = EncryptPasswordView() { keyLabel, password in
            guard let container = self.container else { return }
            Task { [weak self] in
                do {
                    try await Encrypt.encryptFile(container.filePath, with: container.dataFiles, withLabel: keyLabel, withPassword: password)
                    await self?.encrypted()
                } catch {
                    await self?.infoAlert(message: L(.cryptoEncryptionErrorText))
                }
            }
        }
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.modalPresentationStyle = .automatic
        LandingViewController.shared.present(hostingController, animated: true, completion: nil)
    }

    func startDecryptingProcess() {
        if container.addressees.contains(where: { $0.data.isEmpty }) { // TODO: needs better discovery method
            let swiftUIView = DecryptPasswordView(label: self.container.addressees.first?.identifier ?? "") { password in
                do {
                    let decryptedData = try Decrypt.decryptFile(self.containerPath, withPassword: password)
                    self.idCardDecryptDidFinished(success: true,  dataFiles: decryptedData, error: nil)
                } catch {
                    self.idCardDecryptDidFinished(success: false, dataFiles: [:], error: error)
                }
            }
            let hostingController = UIHostingController(rootView: swiftUIView)
            hostingController.modalPresentationStyle = .automatic
            LandingViewController.shared.present(hostingController, animated: true, completion: nil)
        } else {
            let decryptSelectionVC = UIStoryboard.tokenFlow.instantiateViewController(of: TokenFlowSelectionViewController.self)
            decryptSelectionVC.modalPresentationStyle = .overFullScreen
            decryptSelectionVC.idCardDecryptViewControllerDelegate = self
            decryptSelectionVC.addressees = container.addressees
            decryptSelectionVC.containerPath = containerPath
            decryptSelectionVC.isFlowForDecrypting = true
            LandingViewController.shared.present(decryptSelectionVC, animated: false, completion: nil)
        }
    }
}

extension CryptoContainerViewController : IdCardDecryptViewControllerDelegate {

    func idCardDecryptDidFinished(success: Bool, dataFiles: [String: Data], error: Error?) {
        dismiss(animated: false)
        guard success else {
            if let nsError = error as NSError?,
               nsError == .pinBlocked {
                errorAlertWithLink(message: L(.pin1BlockedAlert))
            } else {
                infoAlert(message: L(.decryptionErrorMessage))
            }
            return
        }

        container.dataFiles.removeAll()
        for dataFile in dataFiles {
            guard let destinationPath = MoppFileManager.shared.tempFilePath(withFileName: dataFile.key) else {
                infoAlert(message: L(.decryptionErrorMessage))
                return
            }
            container.dataFiles.append(CryptoDataFile(filename: dataFile.key, filePath: destinationPath))
            MoppFileManager.shared.createFile(atPath: destinationPath, contents: dataFile.value)
        }

        self.isCreated = false
        self.isForPreview = false
        self.isDecrypted = true

        let decryptionSuccess = NotificationMessage(isSuccess: true, text: L(.containerDetailsDecryptionSuccess))
        if !self.notifications.contains(where: { $0 == decryptionSuccess }) {
            self.notifications.append(decryptionSuccess)
        }
        UIAccessibility.post(notification: .screenChanged, argument: L(.containerDetailsDecryptionSuccess))

        self.reloadCryptoData()
    }
}
