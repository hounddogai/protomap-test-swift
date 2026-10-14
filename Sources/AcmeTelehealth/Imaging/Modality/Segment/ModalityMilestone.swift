import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality milestone is in its life cycle.
    enum ModalityMilestoneStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A modality milestone as the modality team keeps it.
    final class ModalityMilestone {
        var code: String
        var label: String
        var discount: Double
        var ward: String
        var description: String
        var limit: Int
        var priority: Int
        var status: ModalityMilestoneStatus

        init(code: String, label: String, discount: Double, ward: String, description: String, limit: Int, priority: Int, status: ModalityMilestoneStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.ward = ward
            self.description = description
            self.limit = limit
            self.priority = priority
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

        func canMoveTo(_ next: ModalityMilestoneStatus) -> Bool {
            switch status {
            case .planned:
                return next == ModalityMilestoneStatus.scheduled || next == ModalityMilestoneStatus.cancelled
            case .scheduled:
                return next == ModalityMilestoneStatus.inProgress
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ModalityMilestoneStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ModalityMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("modality milestone") \(code)"
        }

        func weightedValue() -> Double {
            return ((Double(limit) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> ModalityMilestone {
            return ModalityMilestone(
                code: code,
                label: label,
                discount: discount,
                ward: ward,
                description: description,
                limit: limit,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a modality milestone in status planned.
    static func newModalityMilestone(_ code: String, label: String) -> ModalityMilestone {
        return ModalityMilestone(
            code: code,
            label: label,
            discount: 0.0,
            ward: "",
            description: "",
            limit: 0,
            priority: 0,
            status: ModalityMilestoneStatus.planned
        )
    }
}
