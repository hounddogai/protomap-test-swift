import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach audit is in its life cycle.
    enum OutreachAuditStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a outreach audit and its current status.
    final class OutreachAudit {
        var code: String
        var name: String
        var channel: String
        var tags: [String]
        var updatedAt: Int
        var status: OutreachAuditStatus

        init(code: String, name: String, channel: String, tags: [String], updatedAt: Int, status: OutreachAuditStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.tags = tags
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: OutreachAuditStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == OutreachAuditStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OutreachAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("outreach audit") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(updatedAt)
        }

        func copyValue() -> OutreachAudit {
            return OutreachAudit(
                code: code,
                name: name,
                channel: channel,
                tags: tags,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a outreach audit in status open.
    static func newOutreachAudit(_ code: String, name: String) -> OutreachAudit {
        return OutreachAudit(
            code: code,
            name: name,
            channel: "",
            tags: [],
            updatedAt: 0,
            status: OutreachAuditStatus.`open`
        )
    }
}
