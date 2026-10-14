import AcmePlatform
import Foundation

extension Referrals {
    /// Where a lenient follow up target is in its life cycle.
    enum LenientFollowUpTargetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a lenient follow up target and its current status.
    final class LenientFollowUpTarget {
        var code: String
        var title: String
        var margin: Double
        var updatedAt: Int
        var attempts: Int
        var version: Int
        var graceDays: Int
        var source: String
        var channel: String
        var phone: String
        var cost: Double
        var status: LenientFollowUpTargetStatus

        init(code: String, title: String, margin: Double, updatedAt: Int, attempts: Int, version: Int, graceDays: Int, source: String, channel: String, phone: String, cost: Double, status: LenientFollowUpTargetStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.updatedAt = updatedAt
            self.attempts = attempts
            self.version = version
            self.graceDays = graceDays
            self.source = source
            self.channel = channel
            self.phone = phone
            self.cost = cost
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

        func canMoveTo(_ next: LenientFollowUpTargetStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .resolved:
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
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == LenientFollowUpTargetStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientFollowUpTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient follow up target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netLoad() -> Double {
            return ((Double(updatedAt) - cost) * 100).rounded() / 100
        }

        func copyValue() -> LenientFollowUpTarget {
            return LenientFollowUpTarget(
                code: code,
                title: title,
                margin: margin,
                updatedAt: updatedAt,
                attempts: attempts,
                version: version,
                graceDays: graceDays,
                source: source,
                channel: channel,
                phone: phone,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a lenient follow up target in status open.
    static func newLenientFollowUpTarget(_ code: String, title: String) -> LenientFollowUpTarget {
        return LenientFollowUpTarget(
            code: code,
            title: title,
            margin: 0.0,
            updatedAt: 0,
            attempts: 0,
            version: 0,
            graceDays: 0,
            source: "",
            channel: "",
            phone: "",
            cost: 0.0,
            status: LenientFollowUpTargetStatus.`open`
        )
    }
}
