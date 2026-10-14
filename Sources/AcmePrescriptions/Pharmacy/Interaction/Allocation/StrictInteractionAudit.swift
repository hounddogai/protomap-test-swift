import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a strict interaction audit is in its life cycle.
    enum StrictInteractionAuditStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A strict interaction audit as the interaction team keeps it.
    final class StrictInteractionAudit {
        var code: String
        var label: String
        var startsAt: Int
        var createdAt: Int
        var visible: Bool
        var limit: Int
        var allergy: String
        var budget: Double
        var status: StrictInteractionAuditStatus

        init(code: String, label: String, startsAt: Int, createdAt: Int, visible: Bool, limit: Int, allergy: String, budget: Double, status: StrictInteractionAuditStatus) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.createdAt = createdAt
            self.visible = visible
            self.limit = limit
            self.allergy = allergy
            self.budget = budget
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictInteractionAuditStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == StrictInteractionAuditStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: StrictInteractionAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict interaction audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("strict interaction audit") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(createdAt) - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> StrictInteractionAudit {
            return StrictInteractionAudit(
                code: code,
                label: label,
                startsAt: startsAt,
                createdAt: createdAt,
                visible: visible,
                limit: limit,
                allergy: allergy,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a strict interaction audit in status proposed.
    static func newStrictInteractionAudit(_ code: String, label: String) -> StrictInteractionAudit {
        return StrictInteractionAudit(
            code: code,
            label: label,
            startsAt: 0,
            createdAt: 0,
            visible: false,
            limit: 0,
            allergy: "",
            budget: 0.0,
            status: StrictInteractionAuditStatus.proposed
        )
    }
}
