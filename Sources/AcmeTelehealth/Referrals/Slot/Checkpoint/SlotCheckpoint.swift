import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot checkpoint is in its life cycle.
    enum SlotCheckpointStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A slot checkpoint as the slot team keeps it.
    final class SlotCheckpoint {
        var code: String
        var name: String
        var category: String
        var ownerID: String
        var amount: Double
        var createdAt: Int
        var weight: Double
        var summary: String
        var timezone: String
        var limit: Int
        var status: SlotCheckpointStatus

        init(code: String, name: String, category: String, ownerID: String, amount: Double, createdAt: Int, weight: Double, summary: String, timezone: String, limit: Int, status: SlotCheckpointStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.ownerID = ownerID
            self.amount = amount
            self.createdAt = createdAt
            self.weight = weight
            self.summary = summary
            self.timezone = timezone
            self.limit = limit
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

        func canMoveTo(_ next: SlotCheckpointStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == SlotCheckpointStatus.archived
            case .resolved:
                return next == SlotCheckpointStatus.archived
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

        func moveTo(_ next: SlotCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedExposure() -> Double {
            return ((Double(limit) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> SlotCheckpoint {
            return SlotCheckpoint(
                code: code,
                name: name,
                category: category,
                ownerID: ownerID,
                amount: amount,
                createdAt: createdAt,
                weight: weight,
                summary: summary,
                timezone: timezone,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a slot checkpoint in status open.
    static func newSlotCheckpoint(_ code: String, name: String) -> SlotCheckpoint {
        return SlotCheckpoint(
            code: code,
            name: name,
            category: "",
            ownerID: "",
            amount: 0.0,
            createdAt: 0,
            weight: 0.0,
            summary: "",
            timezone: "",
            limit: 0,
            status: SlotCheckpointStatus.`open`
        )
    }
}
