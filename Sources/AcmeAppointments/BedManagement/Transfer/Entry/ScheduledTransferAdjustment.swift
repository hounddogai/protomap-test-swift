import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a scheduled transfer adjustment is in its life cycle.
    enum ScheduledTransferAdjustmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One scheduled transfer adjustment, with what the planners need to act on it.
    final class ScheduledTransferAdjustment {
        var code: String
        var label: String
        var patientRef: String
        var externalRef: String
        var channel: String
        var discount: Double
        var createdAt: Int
        var segment: String
        var status: ScheduledTransferAdjustmentStatus

        init(code: String, label: String, patientRef: String, externalRef: String, channel: String, discount: Double, createdAt: Int, segment: String, status: ScheduledTransferAdjustmentStatus) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.externalRef = externalRef
            self.channel = channel
            self.discount = discount
            self.createdAt = createdAt
            self.segment = segment
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledTransferAdjustmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ScheduledTransferAdjustmentStatus.withdrawn
            case .approved:
                return next == ScheduledTransferAdjustmentStatus.rejected
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: ScheduledTransferAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled transfer adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedLoad() -> Double {
            return ((discount - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledTransferAdjustment {
            return ScheduledTransferAdjustment(
                code: code,
                label: label,
                patientRef: patientRef,
                externalRef: externalRef,
                channel: channel,
                discount: discount,
                createdAt: createdAt,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a scheduled transfer adjustment in status proposed.
    static func newScheduledTransferAdjustment(_ code: String, label: String) -> ScheduledTransferAdjustment {
        return ScheduledTransferAdjustment(
            code: code,
            label: label,
            patientRef: "",
            externalRef: "",
            channel: "",
            discount: 0.0,
            createdAt: 0,
            segment: "",
            status: ScheduledTransferAdjustmentStatus.proposed
        )
    }
}
