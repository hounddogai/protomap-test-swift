import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a rolling statement preference is in its life cycle.
    enum RollingStatementPreferenceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A rolling statement preference. Its code is unique within a tenant.
    final class RollingStatementPreference {
        var code: String
        var label: String
        var tags: [String]
        var score: Double
        var payer: String
        var status: RollingStatementPreferenceStatus

        init(code: String, label: String, tags: [String], score: Double, payer: String, status: RollingStatementPreferenceStatus) {
            self.code = code
            self.label = label
            self.tags = tags
            self.score = score
            self.payer = payer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingStatementPreferenceStatus) -> Bool {
            switch status {
            case .planned:
                return next == RollingStatementPreferenceStatus.completed || next == RollingStatementPreferenceStatus.cancelled
            case .scheduled:
                return next == RollingStatementPreferenceStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == RollingStatementPreferenceStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingStatementPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling statement preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> RollingStatementPreference {
            return RollingStatementPreference(
                code: code,
                label: label,
                tags: tags,
                score: score,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling statement preference in status planned.
    static func newRollingStatementPreference(_ code: String, label: String) -> RollingStatementPreference {
        return RollingStatementPreference(
            code: code,
            label: label,
            tags: [],
            score: 0.0,
            payer: "",
            status: RollingStatementPreferenceStatus.planned
        )
    }
}
