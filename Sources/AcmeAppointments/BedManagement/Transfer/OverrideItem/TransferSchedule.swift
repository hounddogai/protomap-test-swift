import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer schedule is in its life cycle.
    enum TransferScheduleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A transfer schedule. Its code is unique within a tenant.
    final class TransferSchedule {
        var code: String
        var name: String
        var ceiling: Double
        var label: String
        var copay: Double
        var threshold: Double
        var visitMinutes: Int
        var visible: Bool
        var status: TransferScheduleStatus

        init(code: String, name: String, ceiling: Double, label: String, copay: Double, threshold: Double, visitMinutes: Int, visible: Bool, status: TransferScheduleStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.label = label
            self.copay = copay
            self.threshold = threshold
            self.visitMinutes = visitMinutes
            self.visible = visible
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TransferScheduleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == TransferScheduleStatus.resolved || next == TransferScheduleStatus.reopened
            case .resolved:
                return next == TransferScheduleStatus.reopened || next == TransferScheduleStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: TransferScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("transfer schedule") \(code)"
        }

        func effectiveValue() -> Double {
            return (Double(visitMinutes) * copay * 100).rounded() / 100
        }

        func copyValue() -> TransferSchedule {
            return TransferSchedule(
                code: code,
                name: name,
                ceiling: ceiling,
                label: label,
                copay: copay,
                threshold: threshold,
                visitMinutes: visitMinutes,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a transfer schedule in status open.
    static func newTransferSchedule(_ code: String, name: String) -> TransferSchedule {
        return TransferSchedule(
            code: code,
            name: name,
            ceiling: 0.0,
            label: "",
            copay: 0.0,
            threshold: 0.0,
            visitMinutes: 0,
            visible: false,
            status: TransferScheduleStatus.`open`
        )
    }
}
