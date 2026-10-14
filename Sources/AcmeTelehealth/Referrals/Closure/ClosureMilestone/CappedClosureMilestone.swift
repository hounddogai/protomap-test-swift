import AcmePlatform
import Foundation

extension Referrals {
    /// Where a capped closure milestone is in its life cycle.
    enum CappedClosureMilestoneStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A capped closure milestone. Its code is unique within a tenant.
    final class CappedClosureMilestone {
        var code: String
        var name: String
        var allergy: String
        var title: String
        var ownerID: String
        var region: String
        var ratio: Double
        var status: CappedClosureMilestoneStatus

        init(code: String, name: String, allergy: String, title: String, ownerID: String, region: String, ratio: Double, status: CappedClosureMilestoneStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.title = title
            self.ownerID = ownerID
            self.region = region
            self.ratio = ratio
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

        func canMoveTo(_ next: CappedClosureMilestoneStatus) -> Bool {
            switch status {
            case .`open`:
                return next == CappedClosureMilestoneStatus.inReview || next == CappedClosureMilestoneStatus.archived
            case .inReview:
                switch next {
                case .reopened, .archived:
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

        func moveTo(_ next: CappedClosureMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped closure milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return ratio
        }

        func copyValue() -> CappedClosureMilestone {
            return CappedClosureMilestone(
                code: code,
                name: name,
                allergy: allergy,
                title: title,
                ownerID: ownerID,
                region: region,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a capped closure milestone in status open.
    static func newCappedClosureMilestone(_ code: String, name: String) -> CappedClosureMilestone {
        return CappedClosureMilestone(
            code: code,
            name: name,
            allergy: "",
            title: "",
            ownerID: "",
            region: "",
            ratio: 0.0,
            status: CappedClosureMilestoneStatus.`open`
        )
    }
}
