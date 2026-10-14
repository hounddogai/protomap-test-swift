import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientWorklistTemplate() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-worklist-template")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a lenient worklist template code in its canonical LWT- form.
    static func normalizeLenientWorklistTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LWT-") {
            return clean
        }
        return "LWT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
