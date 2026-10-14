import AcmePlatform
import Foundation

extension Consent {
    /// Where a legacy language policy is in its life cycle.
    enum LegacyLanguagePolicyStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a legacy language policy and its current status.
    final class LegacyLanguagePolicy {
        var code: String
        var title: String
        var durationMinutes: Int
        var graceDays: Int
        var rate: Double
        var minimum: Double
        var status: LegacyLanguagePolicyStatus

        init(code: String, title: String, durationMinutes: Int, graceDays: Int, rate: Double, minimum: Double, status: LegacyLanguagePolicyStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.graceDays = graceDays
            self.rate = rate
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

        func canMoveTo(_ next: LegacyLanguagePolicyStatus) -> Bool {
            switch status {
            case .draft:
                return next == LegacyLanguagePolicyStatus.closed
            case .pending:
                return next == LegacyLanguagePolicyStatus.active || next == LegacyLanguagePolicyStatus.closed
            case .active:
                return next == LegacyLanguagePolicyStatus.suspended || next == LegacyLanguagePolicyStatus.closed
            case .suspended:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyLanguagePolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy language policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedValue() -> Double {
            return ((Double(durationMinutes) + minimum) * 100).rounded() / 100
        }

        func copyValue() -> LegacyLanguagePolicy {
            return LegacyLanguagePolicy(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                graceDays: graceDays,
                rate: rate,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy language policy in status draft.
    static func newLegacyLanguagePolicy(_ code: String, title: String) -> LegacyLanguagePolicy {
        return LegacyLanguagePolicy(
            code: code,
            title: title,
            durationMinutes: 0,
            graceDays: 0,
            rate: 0.0,
            minimum: 0.0,
            status: LegacyLanguagePolicyStatus.draft
        )
    }
}
