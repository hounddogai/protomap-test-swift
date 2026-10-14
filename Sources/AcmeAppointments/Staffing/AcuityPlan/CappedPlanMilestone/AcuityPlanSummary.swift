import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan summary is in its life cycle.
    enum AcuityPlanSummaryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A acuity plan summary as the acuity plan team keeps it.
    final class AcuityPlanSummary {
        var code: String
        var name: String
        var active: Bool
        var label: String
        var cost: Double
        var category: String
        var phone: String
        var notes: String
        var diagnosisCode: String
        var allergy: String
        var graceDays: Int
        var status: AcuityPlanSummaryStatus

        init(code: String, name: String, active: Bool, label: String, cost: Double, category: String, phone: String, notes: String, diagnosisCode: String, allergy: String, graceDays: Int, status: AcuityPlanSummaryStatus) {
            self.code = code
            self.name = name
            self.active = active
            self.label = label
            self.cost = cost
            self.category = category
            self.phone = phone
            self.notes = notes
            self.diagnosisCode = diagnosisCode
            self.allergy = allergy
            self.graceDays = graceDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AcuityPlanSummaryStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == AcuityPlanSummaryStatus.active
            case .active:
                return next == AcuityPlanSummaryStatus.suspended || next == AcuityPlanSummaryStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: AcuityPlanSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
        }

        func weightedExposure() -> Double {
            return ((cost - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanSummary {
            return AcuityPlanSummary(
                code: code,
                name: name,
                active: active,
                label: label,
                cost: cost,
                category: category,
                phone: phone,
                notes: notes,
                diagnosisCode: diagnosisCode,
                allergy: allergy,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a acuity plan summary in status draft.
    static func newAcuityPlanSummary(_ code: String, name: String) -> AcuityPlanSummary {
        return AcuityPlanSummary(
            code: code,
            name: name,
            active: false,
            label: "",
            cost: 0.0,
            category: "",
            phone: "",
            notes: "",
            diagnosisCode: "",
            allergy: "",
            graceDays: 0,
            status: AcuityPlanSummaryStatus.draft
        )
    }
}
