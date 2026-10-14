import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a pending handoff target is in its life cycle.
    enum PendingHandoffTargetStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One pending handoff target, with what the planners need to act on it.
    final class PendingHandoffTarget {
        var code: String
        var label: String
        var revision: Int
        var maximum: Double
        var budget: Double
        var timezone: String
        var procedureCode: String
        var reviewer: String
        var dosageMg: Double
        var status: PendingHandoffTargetStatus

        init(code: String, label: String, revision: Int, maximum: Double, budget: Double, timezone: String, procedureCode: String, reviewer: String, dosageMg: Double, status: PendingHandoffTargetStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.maximum = maximum
            self.budget = budget
            self.timezone = timezone
            self.procedureCode = procedureCode
            self.reviewer = reviewer
            self.dosageMg = dosageMg
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingHandoffTargetStatus) -> Bool {
            switch status {
            case .created:
                return next == PendingHandoffTargetStatus.validated || next == PendingHandoffTargetStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: PendingHandoffTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending handoff target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netExposure() -> Double {
            return ((Double(revision) + budget) * 100).rounded() / 100
        }

        func copyValue() -> PendingHandoffTarget {
            return PendingHandoffTarget(
                code: code,
                label: label,
                revision: revision,
                maximum: maximum,
                budget: budget,
                timezone: timezone,
                procedureCode: procedureCode,
                reviewer: reviewer,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending handoff target in status created.
    static func newPendingHandoffTarget(_ code: String, label: String) -> PendingHandoffTarget {
        return PendingHandoffTarget(
            code: code,
            label: label,
            revision: 0,
            maximum: 0.0,
            budget: 0.0,
            timezone: "",
            procedureCode: "",
            reviewer: "",
            dosageMg: 0.0,
            status: PendingHandoffTargetStatus.created
        )
    }
}
