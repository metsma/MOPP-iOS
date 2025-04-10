//
//  Config.h
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

#import <Foundation/Foundation.h>
#import <CryptoLib/CryptoLib-Swift.h>
#include <cdoc/Configuration.h>
#include <cdoc/NetworkBackend.h>

struct Settings: public libcdoc::Configuration {
    std::string getValue(std::string_view domain, std::string_view param) const final {
        if(param == KEYSERVER_FETCH_URL)
            return [CDoc2Settings.getFetchURL toString];
        if(param == KEYSERVER_SEND_URL)
            return [CDoc2Settings.getPostURL toString];
        return {};
    }
};

struct Network: public libcdoc::NetworkBackend {
    libcdoc::result_t getPeerTLSCertificates(std::vector<std::vector<uint8_t>> &dst, const std::string& url) final {
        libcdoc::NetworkBackend::getPeerTLSCertificates(dst);
        for (NSData *cert in CDoc2Settings.cdoc2Certs) {
            dst.push_back([cert toVector]);
        }
        if (auto cert = [CDoc2Settings.getCert toVector]; !cert.empty()) {
            dst.push_back(std::move(cert));
        }
        return libcdoc::OK;
    }

    libcdoc::result_t getProxyCredentials(ProxyCredentials &cred) const final {
        if (NSDictionary<NSString *, id> *data = [CDoc2Settings proxyCredentials]) {
            cred = {
                .host = [(NSString*)data[CDoc2Settings.kProxyHost] toString],
                .port = [data[CDoc2Settings.kProxyPort] unsignedShortValue],
                .username = [(NSString*)data[CDoc2Settings.kProxyUsername] toString],
                .password = [(NSString*)data[CDoc2Settings.kProxyPassword] toString]
            };
        }
        return libcdoc::OK;
    }
};
