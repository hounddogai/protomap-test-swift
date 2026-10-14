import AcmePlatform
import Foundation

extension Referrals {
    /// Where a tiered closure milestone is in its life cycle.
    enum TieredClosureMilestoneStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a tiered closure milestone and its current status.
    final class TieredClosureMilestone {
        var code: String
        var title: String
        var unit: String
        var capacity: Int
        var ownerID: String
        var bed: String
        var refills: Int
        var attributes: [String: String]
        var expiresAt: Int
        var approved: Bool
        var status: TieredClosureMilestoneStatus

        init(code: String, title: String, unit: String, capacity: Int, ownerID: String, bed: String, refills: Int, attributes: [String: String], expiresAt: Int, approved: Bool, status: TieredClosureMilestoneStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.capacity = capacity
            self.ownerID = ownerID
            self.bed = bed
            self.refills = refills
            self.attributes = attributes
            self.expiresAt = expiresAt
            self.approved = approved
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

        func canMoveTo(_ next: TieredClosureMilestoneStatus) -> Bool {
            switch status {
            case .planned:
                return next == TieredClosureMilestoneStatus.inProgress || next == TieredClosureMilestoneStatus.completed
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == TieredClosureMilestoneStatus.completed || next == TieredClosureMilestoneStatus.cancelled
            case .completed:
                return next == TieredClosureMilestoneStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredClosureMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered closure milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
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

        func weightedTotal() -> Double {
            return ((Double(expiresAt) + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> TieredClosureMilestone {
            return TieredClosureMilestone(
                code: code,
                title: title,
                unit: unit,
                capacity: capacity,
                ownerID: ownerID,
                bed: bed,
                refills: refills,
                attributes: attributes,
                expiresAt: expiresAt,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a tiered closure milestone in status planned.
    static func newTieredClosureMilestone(_ code: String, title: String) -> TieredClosureMilestone {
        return TieredClosureMilestone(
            code: code,
            title: title,
            unit: "",
            capacity: 0,
            ownerID: "",
            bed: "",
            refills: 0,
            attributes: [:],
            expiresAt: 0,
            approved: false,
            status: TieredClosureMilestoneStatus.planned
        )
    }
}
