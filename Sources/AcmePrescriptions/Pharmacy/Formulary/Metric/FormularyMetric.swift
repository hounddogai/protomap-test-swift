import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary metric is in its life cycle.
    enum FormularyMetricStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a formulary metric and its current status.
    final class FormularyMetric {
        var code: String
        var title: String
        var refills: Int
        var budget: Double
        var description: String
        var diagnosisCode: String
        var phone: String
        var status: FormularyMetricStatus

        init(code: String, title: String, refills: Int, budget: Double, description: String, diagnosisCode: String, phone: String, status: FormularyMetricStatus) {
            self.code = code
            self.title = title
            self.refills = refills
            self.budget = budget
            self.description = description
            self.diagnosisCode = diagnosisCode
            self.phone = phone
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

        func canMoveTo(_ next: FormularyMetricStatus) -> Bool {
            switch status {
            case .proposed:
                return next == FormularyMetricStatus.approved || next == FormularyMetricStatus.rejected
            case .approved:
                return next == FormularyMetricStatus.rejected
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

        func moveTo(_ next: FormularyMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedLoad() -> Double {
            return ((budget - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> FormularyMetric {
            return FormularyMetric(
                code: code,
                title: title,
                refills: refills,
                budget: budget,
                description: description,
                diagnosisCode: diagnosisCode,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a formulary metric in status proposed.
    static func newFormularyMetric(_ code: String, title: String) -> FormularyMetric {
        return FormularyMetric(
            code: code,
            title: title,
            refills: 0,
            budget: 0.0,
            description: "",
            diagnosisCode: "",
            phone: "",
            status: FormularyMetricStatus.proposed
        )
    }
}
