import AcmePlatform
import Foundation

extension Consent {
    /// Where a lenient proxy entry is in its life cycle.
    enum LenientProxyEntryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One lenient proxy entry, with what the planners need to act on it.
    final class LenientProxyEntry {
        var code: String
        var label: String
        var summary: String
        var dosageMg: Double
        var budget: Double
        var minimum: Double
        var status: LenientProxyEntryStatus

        init(code: String, label: String, summary: String, dosageMg: Double, budget: Double, minimum: Double, status: LenientProxyEntryStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.dosageMg = dosageMg
            self.budget = budget
            self.minimum = minimum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientProxyEntryStatus) -> Bool {
            switch status {
            case .draft:
                return next == LenientProxyEntryStatus.pending
            case .pending:
                return next == LenientProxyEntryStatus.active || next == LenientProxyEntryStatus.closed
            case .active:
                return next == LenientProxyEntryStatus.suspended
            case .suspended:
                return next == LenientProxyEntryStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientProxyEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient proxy entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("lenient proxy entry") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((budget - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> LenientProxyEntry {
            return LenientProxyEntry(
                code: code,
                label: label,
                summary: summary,
                dosageMg: dosageMg,
                budget: budget,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient proxy entry in status draft.
    static func newLenientProxyEntry(_ code: String, label: String) -> LenientProxyEntry {
        return LenientProxyEntry(
            code: code,
            label: label,
            summary: "",
            dosageMg: 0.0,
            budget: 0.0,
            minimum: 0.0,
            status: LenientProxyEntryStatus.draft
        )
    }
}
