import Foundation

extension String {
    func addingPercentEncodingForRFC3986() -> String? {
        // Permitimos todos los caracteres no reservados, excluyendo caracteres reservados excepto '#'
        let allowedCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return self.addingPercentEncoding(withAllowedCharacters: allowedCharacters)?
            .replacingOccurrences(of: ":", with: "%3A")
            .replacingOccurrences(of: "/", with: "%2F")
            .replacingOccurrences(of: "?", with: "%3F")
            .replacingOccurrences(of: "#", with: "%23")
            .replacingOccurrences(of: "[", with: "%5B")
            .replacingOccurrences(of: "]", with: "%5D")
            .replacingOccurrences(of: "@", with: "%40")
            .replacingOccurrences(of: "!", with: "%21")
            .replacingOccurrences(of: "$", with: "%24")
            .replacingOccurrences(of: "&", with: "%26")
            .replacingOccurrences(of: "'", with: "%27")
            .replacingOccurrences(of: "(", with: "%28")
            .replacingOccurrences(of: ")", with: "%29")
            .replacingOccurrences(of: "*", with: "%2A")
            .replacingOccurrences(of: "+", with: "%2B")
            .replacingOccurrences(of: ",", with: "%2C")
            .replacingOccurrences(of: ";", with: "%3B")
            .replacingOccurrences(of: "=", with: "%3D")
    }
}
