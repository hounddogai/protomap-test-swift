import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a pending alert quota is in its life cycle.
    enum PendingAlertQuotaStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A pending alert quota. Its code is unique within a tenant.
    final class PendingAlertQuota {
        var code: String
        var title: String
        var durationMinutes: Int
        var segment: String
        var amount: Double
        var pinned: Bool
        var refills: Int
        var version: Int
        var channel: String
        var status: PendingAlertQuotaStatus

        init(code: String, title: String, durationMinutes: Int, segment: String, amount: Double, pinned: Bool, refills: Int, version: Int, channel: String, status: PendingAlertQuotaStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.segment = segment
            self.amount = amount
            self.pinned = pinned
            self.refills = refills
            self.version = version
            self.channel = channel
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

        func canMoveTo(_ next: PendingAlertQuotaStatus) -> Bool {
            switch status {
            case .planned:
                return next == PendingAlertQuotaStatus.completed || next == PendingAlertQuotaStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PendingAlertQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending alert quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveTotal() -> Double {
            return ((Double(version) + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> PendingAlertQuota {
            return PendingAlertQuota(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                segment: segment,
                amount: amount,
                pinned: pinned,
                refills: refills,
                version: version,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a pending alert quota in status planned.
    static func newPendingAlertQuota(_ code: String, title: String) -> PendingAlertQuota {
        return PendingAlertQuota(
            code: code,
            title: title,
            durationMinutes: 0,
            segment: "",
            amount: 0.0,
            pinned: false,
            refills: 0,
            version: 0,
            channel: "",
            status: PendingAlertQuotaStatus.planned
        )
    }
}
