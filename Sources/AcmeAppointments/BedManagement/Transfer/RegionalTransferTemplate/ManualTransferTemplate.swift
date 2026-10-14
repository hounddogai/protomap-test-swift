import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a manual transfer template is in its life cycle.
    enum ManualTransferTemplateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A manual transfer template as the transfer team keeps it.
    final class ManualTransferTemplate {
        var code: String
        var title: String
        var reviewer: String
        var maximum: Double
        var priority: Int
        var copay: Double
        var attempts: Int
        var ownerID: String
        var status: ManualTransferTemplateStatus

        init(code: String, title: String, reviewer: String, maximum: Double, priority: Int, copay: Double, attempts: Int, ownerID: String, status: ManualTransferTemplateStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.maximum = maximum
            self.priority = priority
            self.copay = copay
            self.attempts = attempts
            self.ownerID = ownerID
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

        func canMoveTo(_ next: ManualTransferTemplateStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ManualTransferTemplateStatus.completed || next == ManualTransferTemplateStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: ManualTransferTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual transfer template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedExposure() -> Double {
            return ((maximum + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> ManualTransferTemplate {
            return ManualTransferTemplate(
                code: code,
                title: title,
                reviewer: reviewer,
                maximum: maximum,
                priority: priority,
                copay: copay,
                attempts: attempts,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a manual transfer template in status planned.
    static func newManualTransferTemplate(_ code: String, title: String) -> ManualTransferTemplate {
        return ManualTransferTemplate(
            code: code,
            title: title,
            reviewer: "",
            maximum: 0.0,
            priority: 0,
            copay: 0.0,
            attempts: 0,
            ownerID: "",
            status: ManualTransferTemplateStatus.planned
        )
    }
}
