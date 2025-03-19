//
//  DecryptPasswordView.swift
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

public struct DecryptPasswordView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var password: String = ""
    public var label: String
    public var onDecrypt: (String) -> Void

    public init(label: String, onDecrypt: @escaping (String) -> Void) {
        self.label = label
        self.onDecrypt = onDecrypt
    }

    public var body: some View {
        VStack(spacing: 20) {
            Text("Enter Password")
                .font(.headline)

            Text("Please enter a password to decrypt the file.")
                .font(.subheadline)
                .foregroundColor(.gray)

            VStack(alignment: .leading, spacing: 5) {
                Text(label)
                    .font(.footnote)
                    .foregroundColor(.gray)

                SecureField("Enter password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
            }

            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.red)

                Spacer()

                Button("Decrypt") {
                    onDecrypt(password)
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(password.isEmpty)
            }
            .padding()
        }
        .padding()
    }
}

struct DecryptPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        DecryptPasswordView(label: "Password label") { password in
            print("Mock decryption with password: \(password)")
        }
    }
}
