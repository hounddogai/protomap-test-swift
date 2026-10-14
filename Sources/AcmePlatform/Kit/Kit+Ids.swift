import Foundation

extension Kit.IDs {
    public static func newID(_ prefix: String, seq: Int) -> String {
        return "\(prefix.uppercased())-\(String(repeating: "0", count: Swift.max(0, 6 - String(seq).count)) + String(seq))"
    }

    public static func shortHash(_ s: String) -> String {
        return String(repeating: "0", count: Swift.max(0, 5 - String(Kit.stableHash(s) % 100000).count)) + String(Kit.stableHash(s) % 100000)
    }

    /// Reports whether s looks like an identifier NewID made with prefix.
    public static func isReference(_ s: String, prefix: String) -> Bool {
        if !s.hasPrefix(prefix.uppercased() + "-") {
            return false
        }
        return s.count == prefix.count + 7
    }

    public static func withCheckDigit(_ s: String) -> String {
        return "\(s)\(Kit.stableHash(s) % 10)"
    }
}
