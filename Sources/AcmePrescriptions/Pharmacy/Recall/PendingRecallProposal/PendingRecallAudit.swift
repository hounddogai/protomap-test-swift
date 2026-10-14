import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a pending recall audit is in its life cycle.
    enum PendingRecallAuditStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A pending recall audit as the recall team keeps it.
    final class PendingRecallAudit {
        var code: String
        var title: String
        var retries: Int
        var tags: [String]
        var ward: String
        var visitMinutes: Int
        var status: PendingRecallAuditStatus

        init(code: String, title: String, retries: Int, tags: [String], ward: String, visitMinutes: Int, status: PendingRecallAuditStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.tags = tags
            self.ward = ward
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: PendingRecallAuditStatus) -> Bool {
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
                return next == PendingRecallAuditStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingRecallAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending recall audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveExposure() -> Double {
            return (Double(visitMinutes) * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> PendingRecallAudit {
            return PendingRecallAudit(
                code: code,
                title: title,
                retries: retries,
                tags: tags,
                ward: ward,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a pending recall audit in status planned.
    static func newPendingRecallAudit(_ code: String, title: String) -> PendingRecallAudit {
        return PendingRecallAudit(
            code: code,
            title: title,
            retries: 0,
            tags: [],
            ward: "",
            visitMinutes: 0,
            status: PendingRecallAuditStatus.planned
        )
    }
}
