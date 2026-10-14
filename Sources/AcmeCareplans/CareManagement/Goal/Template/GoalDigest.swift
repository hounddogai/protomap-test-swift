import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal digest is in its life cycle.
    enum GoalDigestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A goal digest as the goal team keeps it.
    final class GoalDigest {
        var code: String
        var name: String
        var channel: String
        var region: String
        var expiresAt: Int
        var updatedAt: Int
        var capacity: Int
        var discount: Double
        var attributes: [String: String]
        var status: GoalDigestStatus

        init(code: String, name: String, channel: String, region: String, expiresAt: Int, updatedAt: Int, capacity: Int, discount: Double, attributes: [String: String], status: GoalDigestStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.region = region
            self.expiresAt = expiresAt
            self.updatedAt = updatedAt
            self.capacity = capacity
            self.discount = discount
            self.attributes = attributes
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

        func canMoveTo(_ next: GoalDigestStatus) -> Bool {
            switch status {
            case .`open`:
                return next == GoalDigestStatus.reopened
            case .inReview:
                return next == GoalDigestStatus.resolved || next == GoalDigestStatus.archived
            case .resolved:
                return next == GoalDigestStatus.reopened
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

        func moveTo(_ next: GoalDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveValue() -> Double {
            return ((Double(capacity) - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> GoalDigest {
            return GoalDigest(
                code: code,
                name: name,
                channel: channel,
                region: region,
                expiresAt: expiresAt,
                updatedAt: updatedAt,
                capacity: capacity,
                discount: discount,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a goal digest in status open.
    static func newGoalDigest(_ code: String, name: String) -> GoalDigest {
        return GoalDigest(
            code: code,
            name: name,
            channel: "",
            region: "",
            expiresAt: 0,
            updatedAt: 0,
            capacity: 0,
            discount: 0.0,
            attributes: [:],
            status: GoalDigestStatus.`open`
        )
    }
}
