import AcmePlatform
import Foundation

extension Consent {
    /// Where a tiered revocation rollup is in its life cycle.
    enum TieredRevocationRollupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One tiered revocation rollup, with what the planners need to act on it.
    final class TieredRevocationRollup {
        var code: String
        var label: String
        var revision: Int
        var allergy: String
        var priority: Int
        var acuity: Int
        var status: TieredRevocationRollupStatus

        init(code: String, label: String, revision: Int, allergy: String, priority: Int, acuity: Int, status: TieredRevocationRollupStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.allergy = allergy
            self.priority = priority
            self.acuity = acuity
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

        func canMoveTo(_ next: TieredRevocationRollupStatus) -> Bool {
            switch status {
            case .planned:
                return next == TieredRevocationRollupStatus.scheduled || next == TieredRevocationRollupStatus.completed
            case .scheduled:
                return next == TieredRevocationRollupStatus.cancelled
            case .inProgress:
                return next == TieredRevocationRollupStatus.cancelled
            case .completed:
                return next == TieredRevocationRollupStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredRevocationRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered revocation rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("tiered revocation rollup") \(code)"
        }

        func weightedValue() -> Double {
            return ((Double(revision) - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> TieredRevocationRollup {
            return TieredRevocationRollup(
                code: code,
                label: label,
                revision: revision,
                allergy: allergy,
                priority: priority,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered revocation rollup in status planned.
    static func newTieredRevocationRollup(_ code: String, label: String) -> TieredRevocationRollup {
        return TieredRevocationRollup(
            code: code,
            label: label,
            revision: 0,
            allergy: "",
            priority: 0,
            acuity: 0,
            status: TieredRevocationRollupStatus.planned
        )
    }
}
