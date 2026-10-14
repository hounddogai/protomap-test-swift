import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a rolling care gap adjustment is in its life cycle.
    enum RollingCareGapAdjustmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A rolling care gap adjustment. Its code is unique within a tenant.
    final class RollingCareGapAdjustment {
        var code: String
        var label: String
        var timezone: String
        var notes: String
        var acuity: Int
        var checksum: String
        var priority: Int
        var updatedAt: Int
        var phone: String
        var summary: String
        var status: RollingCareGapAdjustmentStatus

        init(code: String, label: String, timezone: String, notes: String, acuity: Int, checksum: String, priority: Int, updatedAt: Int, phone: String, summary: String, status: RollingCareGapAdjustmentStatus) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.notes = notes
            self.acuity = acuity
            self.checksum = checksum
            self.priority = priority
            self.updatedAt = updatedAt
            self.phone = phone
            self.summary = summary
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

        func canMoveTo(_ next: RollingCareGapAdjustmentStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
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
                return next == RollingCareGapAdjustmentStatus.completed
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

        func moveTo(_ next: RollingCareGapAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling care gap adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedExposure() -> Double {
            return ((Double(updatedAt) - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> RollingCareGapAdjustment {
            return RollingCareGapAdjustment(
                code: code,
                label: label,
                timezone: timezone,
                notes: notes,
                acuity: acuity,
                checksum: checksum,
                priority: priority,
                updatedAt: updatedAt,
                phone: phone,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling care gap adjustment in status planned.
    static func newRollingCareGapAdjustment(_ code: String, label: String) -> RollingCareGapAdjustment {
        return RollingCareGapAdjustment(
            code: code,
            label: label,
            timezone: "",
            notes: "",
            acuity: 0,
            checksum: "",
            priority: 0,
            updatedAt: 0,
            phone: "",
            summary: "",
            status: RollingCareGapAdjustmentStatus.planned
        )
    }
}
