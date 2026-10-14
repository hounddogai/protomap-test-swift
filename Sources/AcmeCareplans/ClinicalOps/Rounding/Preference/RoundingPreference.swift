import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding preference is in its life cycle.
    enum RoundingPreferenceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a rounding preference and its current status.
    final class RoundingPreference {
        var code: String
        var label: String
        var source: String
        var retries: Int
        var timezone: String
        var status: RoundingPreferenceStatus

        init(code: String, label: String, source: String, retries: Int, timezone: String, status: RoundingPreferenceStatus) {
            self.code = code
            self.label = label
            self.source = source
            self.retries = retries
            self.timezone = timezone
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

        func canMoveTo(_ next: RoundingPreferenceStatus) -> Bool {
            switch status {
            case .draft:
                return next == RoundingPreferenceStatus.pending || next == RoundingPreferenceStatus.suspended
            case .pending:
                return next == RoundingPreferenceStatus.active || next == RoundingPreferenceStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == RoundingPreferenceStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RoundingPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return Double(retries)
        }

        func copyValue() -> RoundingPreference {
            return RoundingPreference(
                code: code,
                label: label,
                source: source,
                retries: retries,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a rounding preference in status draft.
    static func newRoundingPreference(_ code: String, label: String) -> RoundingPreference {
        return RoundingPreference(
            code: code,
            label: label,
            source: "",
            retries: 0,
            timezone: "",
            status: RoundingPreferenceStatus.draft
        )
    }
}
