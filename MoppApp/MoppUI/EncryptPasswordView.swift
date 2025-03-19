//
//  EncryptPasswordView.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2025 Riigi Infosüsteemi Amet
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

import SwiftUI

public struct EncryptPasswordView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var keyLabel: String = ""
    @State private var password: String = ""
    @State private var repeatPassword: String = ""

    public var onEncrypt: (String, String) -> Void

    public init(onEncrypt: @escaping (String, String) -> Void) {
        self.onEncrypt = onEncrypt
    }

    public var body: some View {
        VStack(spacing: 20) {
            Text("Enter Password")
                .font(.headline)

            Text("Please enter a password to encrypt the document.")
                .font(.subheadline)
                .foregroundColor(.gray)

            VStack(spacing: 10) {
                TextField("Key label", text: $keyLabel)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                SecureField("Enter a password to encrypt the document", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                SecureField("Repeat password", text: $repeatPassword)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
            }

            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.red)

                Spacer()

                Button("Encrypt") {
                    onEncrypt(keyLabel, password)
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(password.isEmpty || repeatPassword.isEmpty || password != repeatPassword)
            }
            .padding()
        }
        .padding()
    }
}

struct EncryptPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        EncryptPasswordView { password, keyLabel in
            print("Encrypting with password: \(password), keyLabel: \(keyLabel)")
        }
    }
}
