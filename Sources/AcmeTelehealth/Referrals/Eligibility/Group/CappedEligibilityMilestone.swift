import AcmePlatform
import Foundation

extension Referrals {
    /// Where a capped eligibility milestone is in its life cycle.
    enum CappedEligibilityMilestoneStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One capped eligibility milestone, with what the planners need to act on it.
    final class CappedEligibilityMilestone {
        var code: String
        var name: String
        var limit: Int
        var createdAt: Int
        var source: String
        var weight: Double
        var approved: Bool
        var unit: String
        var status: CappedEligibilityMilestoneStatus

        init(code: String, name: String, limit: Int, createdAt: Int, source: String, weight: Double, approved: Bool, unit: String, status: CappedEligibilityMilestoneStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.createdAt = createdAt
            self.source = source
            self.weight = weight
            self.approved = approved
            self.unit = unit
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

        func canMoveTo(_ next: CappedEligibilityMilestoneStatus) -> Bool {
            switch status {
            case .`open`:
                return next == CappedEligibilityMilestoneStatus.inReview
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
                return next == CappedEligibilityMilestoneStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedEligibilityMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped eligibility milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedValue() -> Double {
            return ((weight + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> CappedEligibilityMilestone {
            return CappedEligibilityMilestone(
                code: code,
                name: name,
                limit: limit,
                createdAt: createdAt,
                source: source,
                weight: weight,
                approved: approved,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a capped eligibility milestone in status open.
    static func newCappedEligibilityMilestone(_ code: String, name: String) -> CappedEligibilityMilestone {
        return CappedEligibilityMilestone(
            code: code,
            name: name,
            limit: 0,
            createdAt: 0,
            source: "",
            weight: 0.0,
            approved: false,
            unit: "",
            status: CappedEligibilityMilestoneStatus.`open`
        )
    }
}
