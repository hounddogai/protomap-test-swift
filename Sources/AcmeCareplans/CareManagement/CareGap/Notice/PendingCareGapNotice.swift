import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a pending care gap notice is in its life cycle.
    enum PendingCareGapNoticeStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A pending care gap notice as the care gap team keeps it.
    final class PendingCareGapNotice {
        var code: String
        var label: String
        var threshold: Double
        var timezone: String
        var phone: String
        var retries: Int
        var priority: Int
        var budget: Double
        var status: PendingCareGapNoticeStatus

        init(code: String, label: String, threshold: Double, timezone: String, phone: String, retries: Int, priority: Int, budget: Double, status: PendingCareGapNoticeStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.timezone = timezone
            self.phone = phone
            self.retries = retries
            self.priority = priority
            self.budget = budget
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

        func canMoveTo(_ next: PendingCareGapNoticeStatus) -> Bool {
            switch status {
            case .requested:
                return next == PendingCareGapNoticeStatus.revoked || next == PendingCareGapNoticeStatus.expired
            case .granted:
                return next == PendingCareGapNoticeStatus.revoked || next == PendingCareGapNoticeStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: PendingCareGapNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending care gap notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedTotal() -> Double {
            return ((Double(priority) + budget) * 100).rounded() / 100
        }

        func copyValue() -> PendingCareGapNotice {
            return PendingCareGapNotice(
                code: code,
                label: label,
                threshold: threshold,
                timezone: timezone,
                phone: phone,
                retries: retries,
                priority: priority,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending care gap notice in status requested.
    static func newPendingCareGapNotice(_ code: String, label: String) -> PendingCareGapNotice {
        return PendingCareGapNotice(
            code: code,
            label: label,
            threshold: 0.0,
            timezone: "",
            phone: "",
            retries: 0,
            priority: 0,
            budget: 0.0,
            status: PendingCareGapNoticeStatus.requested
        )
    }
}
