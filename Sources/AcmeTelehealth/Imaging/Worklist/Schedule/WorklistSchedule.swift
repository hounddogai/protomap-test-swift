import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist schedule is in its life cycle.
    enum WorklistScheduleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A worklist schedule. Its code is unique within a tenant.
    final class WorklistSchedule {
        var code: String
        var title: String
        var approved: Bool
        var label: String
        var ceiling: Double
        var expiresAt: Int
        var maximum: Double
        var status: WorklistScheduleStatus

        init(code: String, title: String, approved: Bool, label: String, ceiling: Double, expiresAt: Int, maximum: Double, status: WorklistScheduleStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.label = label
            self.ceiling = ceiling
            self.expiresAt = expiresAt
            self.maximum = maximum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WorklistScheduleStatus) -> Bool {
            switch status {
            case .requested:
                return next == WorklistScheduleStatus.revoked
            case .granted:
                return next == WorklistScheduleStatus.revoked || next == WorklistScheduleStatus.expired
            case .revoked:
                return next == WorklistScheduleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WorklistScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("worklist schedule") \(code)"
        }

        func netTotal() -> Double {
            return (Double(expiresAt) * maximum * 100).rounded() / 100
        }

        func copyValue() -> WorklistSchedule {
            return WorklistSchedule(
                code: code,
                title: title,
                approved: approved,
                label: label,
                ceiling: ceiling,
                expiresAt: expiresAt,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a worklist schedule in status requested.
    static func newWorklistSchedule(_ code: String, title: String) -> WorklistSchedule {
        return WorklistSchedule(
            code: code,
            title: title,
            approved: false,
            label: "",
            ceiling: 0.0,
            expiresAt: 0,
            maximum: 0.0,
            status: WorklistScheduleStatus.requested
        )
    }
}
