import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBedBoardDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("bed-board-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a bed board draft code in its canonical BBD- form.
    static func normalizeBedBoardDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BBD-") {
            return clean
        }
        return "BBD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 96393.0, in order.
    static func bedBoardDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 96393.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
