import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 23254.0, in order.
    static func manualOutreachManifestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 23254.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func manualOutreachManifestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualOutreachManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-outreach-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a manual outreach manifest code in its canonical MOM- form.
    static func normalizeManualOutreachManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MOM-") {
            return clean
        }
        return "MOM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
