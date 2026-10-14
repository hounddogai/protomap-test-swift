import AcmePlatform
import Foundation

extension BedManagement {
    static func adaptiveDischargePlanBundleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Puts a adaptive discharge plan bundle code in its canonical ADPB- form.
    static func normalizeAdaptiveDischargePlanBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ADPB-") {
            return clean
        }
        return "ADPB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
