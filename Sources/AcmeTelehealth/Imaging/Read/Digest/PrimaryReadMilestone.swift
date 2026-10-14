import AcmePlatform
import Foundation

extension Imaging {
    /// Where a primary read milestone is in its life cycle.
    enum PrimaryReadMilestoneStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One primary read milestone, with what the planners need to act on it.
    final class PrimaryReadMilestone {
        var code: String
        var title: String
        var tags: [String]
        var dosageMg: Double
        var locale: String
        var refills: Int
        var amount: Double
        var facility: String
        var allergy: String
        var budget: Double
        var status: PrimaryReadMilestoneStatus

        init(code: String, title: String, tags: [String], dosageMg: Double, locale: String, refills: Int, amount: Double, facility: String, allergy: String, budget: Double, status: PrimaryReadMilestoneStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.dosageMg = dosageMg
            self.locale = locale
            self.refills = refills
            self.amount = amount
            self.facility = facility
            self.allergy = allergy
            self.budget = budget
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

        func canMoveTo(_ next: PrimaryReadMilestoneStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == PrimaryReadMilestoneStatus.completed || next == PrimaryReadMilestoneStatus.cancelled
            case .completed:
                return next == PrimaryReadMilestoneStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryReadMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary read milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary read milestone") \(code)"
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
            return (Double(refills) * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> PrimaryReadMilestone {
            return PrimaryReadMilestone(
                code: code,
                title: title,
                tags: tags,
                dosageMg: dosageMg,
                locale: locale,
                refills: refills,
                amount: amount,
                facility: facility,
                allergy: allergy,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a primary read milestone in status planned.
    static func newPrimaryReadMilestone(_ code: String, title: String) -> PrimaryReadMilestone {
        return PrimaryReadMilestone(
            code: code,
            title: title,
            tags: [],
            dosageMg: 0.0,
            locale: "",
            refills: 0,
            amount: 0.0,
            facility: "",
            allergy: "",
            budget: 0.0,
            status: PrimaryReadMilestoneStatus.planned
        )
    }
}
