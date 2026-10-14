import AcmePlatform
import Foundation

extension Imaging {
    /// Where a global worklist plan is in its life cycle.
    enum GlobalWorklistPlanStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One global worklist plan, with what the planners need to act on it.
    final class GlobalWorklistPlan {
        var code: String
        var label: String
        var archived: Bool
        var ratio: Double
        var procedureCode: String
        var notes: String
        var allergy: String
        var title: String
        var updatedAt: Int
        var status: GlobalWorklistPlanStatus

        init(code: String, label: String, archived: Bool, ratio: Double, procedureCode: String, notes: String, allergy: String, title: String, updatedAt: Int, status: GlobalWorklistPlanStatus) {
            self.code = code
            self.label = label
            self.archived = archived
            self.ratio = ratio
            self.procedureCode = procedureCode
            self.notes = notes
            self.allergy = allergy
            self.title = title
            self.updatedAt = updatedAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalWorklistPlanStatus) -> Bool {
            switch status {
            case .created:
                return next == GlobalWorklistPlanStatus.validated || next == GlobalWorklistPlanStatus.retired
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == GlobalWorklistPlanStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalWorklistPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global worklist plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("global worklist plan") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((Double(updatedAt) + ratio) * 100).rounded() / 100
        }

        func copyValue() -> GlobalWorklistPlan {
            return GlobalWorklistPlan(
                code: code,
                label: label,
                archived: archived,
                ratio: ratio,
                procedureCode: procedureCode,
                notes: notes,
                allergy: allergy,
                title: title,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global worklist plan in status created.
    static func newGlobalWorklistPlan(_ code: String, label: String) -> GlobalWorklistPlan {
        return GlobalWorklistPlan(
            code: code,
            label: label,
            archived: false,
            ratio: 0.0,
            procedureCode: "",
            notes: "",
            allergy: "",
            title: "",
            updatedAt: 0,
            status: GlobalWorklistPlanStatus.created
        )
    }
}
