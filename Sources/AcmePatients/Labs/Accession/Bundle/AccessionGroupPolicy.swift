import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAccessionGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("accession-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a accession group code in its canonical AG- form.
    static func normalizeAccessionGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AG-") {
            return clean
        }
        return "AG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeAccessionGroupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func accessionGroupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.1
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
