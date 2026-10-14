import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan record is in its life cycle.
    enum AcuityPlanRecordStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A acuity plan record as the acuity plan team keeps it.
    final class AcuityPlanRecord {
        var code: String
        var label: String
        var ceiling: Double
        var currency: String
        var cost: Double
        var archived: Bool
        var phone: String
        var status: AcuityPlanRecordStatus

        init(code: String, label: String, ceiling: Double, currency: String, cost: Double, archived: Bool, phone: String, status: AcuityPlanRecordStatus) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.currency = currency
            self.cost = cost
            self.archived = archived
            self.phone = phone
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

        func canMoveTo(_ next: AcuityPlanRecordStatus) -> Bool {
            switch status {
            case .planned:
                return next == AcuityPlanRecordStatus.completed
            case .scheduled:
                return next == AcuityPlanRecordStatus.inProgress || next == AcuityPlanRecordStatus.cancelled
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == AcuityPlanRecordStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AcuityPlanRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netValue() -> Double {
            return (ceiling * cost * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanRecord {
            return AcuityPlanRecord(
                code: code,
                label: label,
                ceiling: ceiling,
                currency: currency,
                cost: cost,
                archived: archived,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a acuity plan record in status planned.
    static func newAcuityPlanRecord(_ code: String, label: String) -> AcuityPlanRecord {
        return AcuityPlanRecord(
            code: code,
            label: label,
            ceiling: 0.0,
            currency: "",
            cost: 0.0,
            archived: false,
            phone: "",
            status: AcuityPlanRecordStatus.planned
        )
    }
}
