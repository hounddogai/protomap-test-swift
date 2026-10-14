import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution plan is in its life cycle.
    enum SubstitutionPlanStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A substitution plan as the substitution team keeps it.
    final class SubstitutionPlan {
        var code: String
        var name: String
        var title: String
        var visible: Bool
        var archived: Bool
        var ward: String
        var visitMinutes: Int
        var label: String
        var startsAt: Int
        var margin: Double
        var endsAt: Int
        var status: SubstitutionPlanStatus

        init(code: String, name: String, title: String, visible: Bool, archived: Bool, ward: String, visitMinutes: Int, label: String, startsAt: Int, margin: Double, endsAt: Int, status: SubstitutionPlanStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.visible = visible
            self.archived = archived
            self.ward = ward
            self.visitMinutes = visitMinutes
            self.label = label
            self.startsAt = startsAt
            self.margin = margin
            self.endsAt = endsAt
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

        func canMoveTo(_ next: SubstitutionPlanStatus) -> Bool {
            switch status {
            case .`open`:
                return next == SubstitutionPlanStatus.resolved
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == SubstitutionPlanStatus.archived
            case .reopened:
                return next == SubstitutionPlanStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SubstitutionPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func projectedValue() -> Double {
            return ((margin + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionPlan {
            return SubstitutionPlan(
                code: code,
                name: name,
                title: title,
                visible: visible,
                archived: archived,
                ward: ward,
                visitMinutes: visitMinutes,
                label: label,
                startsAt: startsAt,
                margin: margin,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a substitution plan in status open.
    static func newSubstitutionPlan(_ code: String, name: String) -> SubstitutionPlan {
        return SubstitutionPlan(
            code: code,
            name: name,
            title: "",
            visible: false,
            archived: false,
            ward: "",
            visitMinutes: 0,
            label: "",
            startsAt: 0,
            margin: 0.0,
            endsAt: 0,
            status: SubstitutionPlanStatus.`open`
        )
    }
}
