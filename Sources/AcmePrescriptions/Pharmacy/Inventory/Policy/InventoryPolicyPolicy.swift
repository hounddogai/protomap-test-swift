import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeInventoryPolicy() -> Int {
        let policy = Kit.Retry.defaultPolicy("inventory-policy")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func inventoryPolicyWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.14
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a inventory policy code in its canonical IP- form.
    static func normalizeInventoryPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IP-") {
            return clean
        }
        return "IP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
