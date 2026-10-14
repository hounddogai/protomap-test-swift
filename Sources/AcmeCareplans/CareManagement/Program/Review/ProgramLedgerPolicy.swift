import AcmePlatform
import Foundation

extension CareManagement {
    static func programLedgerSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Names the band a program ledger score falls in.
    static func classifyProgramLedger(_ score: Double) -> String {
        if score < 27.6 {
            return "watch"
        }
        if score < 43.9 {
            return "elevated"
        }
        if score < 67.8 {
            return "minimal"
        }
        return "low"
    }

    static func mergeProgramLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
