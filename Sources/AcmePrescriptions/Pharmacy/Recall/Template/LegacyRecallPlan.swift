import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a legacy recall plan is in its life cycle.
    enum LegacyRecallPlanStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One legacy recall plan, with what the planners need to act on it.
    final class LegacyRecallPlan {
        var code: String
        var name: String
        var title: String
        var bed: String
        var notes: String
        var allergy: String
        var ward: String
        var amount: Double
        var status: LegacyRecallPlanStatus

        init(code: String, name: String, title: String, bed: String, notes: String, allergy: String, ward: String, amount: Double, status: LegacyRecallPlanStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.bed = bed
            self.notes = notes
            self.allergy = allergy
            self.ward = ward
            self.amount = amount
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

        func canMoveTo(_ next: LegacyRecallPlanStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LegacyRecallPlanStatus.inReview || next == LegacyRecallPlanStatus.archived
            case .inReview:
                return next == LegacyRecallPlanStatus.reopened || next == LegacyRecallPlanStatus.archived
            case .resolved:
                return next == LegacyRecallPlanStatus.reopened || next == LegacyRecallPlanStatus.archived
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

        func moveTo(_ next: LegacyRecallPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy recall plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy recall plan") \(code)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> LegacyRecallPlan {
            return LegacyRecallPlan(
                code: code,
                name: name,
                title: title,
                bed: bed,
                notes: notes,
                allergy: allergy,
                ward: ward,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a legacy recall plan in status open.
    static func newLegacyRecallPlan(_ code: String, name: String) -> LegacyRecallPlan {
        return LegacyRecallPlan(
            code: code,
            name: name,
            title: "",
            bed: "",
            notes: "",
            allergy: "",
            ward: "",
            amount: 0.0,
            status: LegacyRecallPlanStatus.`open`
        )
    }
}
