import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a lenient worklist group code in its canonical LWG- form.
    static func normalizeLenientWorklistGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LWG-") {
            return clean
        }
        return "LWG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func lenientWorklistGroupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.79
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientWorklistGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-worklist-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
