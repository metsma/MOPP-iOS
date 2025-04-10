//
//  ManualProxy.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2023 Riigi Infosüsteemi Amet
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

import SkSigningLib

public class ManualProxy {

    public static func getManualProxyConfiguration() -> Proxy {
        let proxy = CDoc2Settings.proxyCredentials()
        return Proxy(
            setting: DefaultsHelper.proxySetting,
            host: proxy?[CDoc2Settings.kProxyHost] as? String ?? "",
            port: proxy?[CDoc2Settings.kProxyPort] as? Int ?? 80,
            username: proxy?[CDoc2Settings.kProxyUsername] as? String ?? "",
            password: proxy?[CDoc2Settings.kProxyPassword] as? String ?? "")
    }
}
