import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility forecast is in its life cycle.
    enum EligibilityForecastStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A eligibility forecast as the eligibility team keeps it.
    final class EligibilityForecast {
        var code: String
        var label: String
        var weight: Double
        var patientRef: String
        var ward: String
        var acuity: Int
        var visible: Bool
        var status: EligibilityForecastStatus

        init(code: String, label: String, weight: Double, patientRef: String, ward: String, acuity: Int, visible: Bool, status: EligibilityForecastStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.patientRef = patientRef
            self.ward = ward
            self.acuity = acuity
            self.visible = visible
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

        func canMoveTo(_ next: EligibilityForecastStatus) -> Bool {
            switch status {
            case .draft:
                return next == EligibilityForecastStatus.pending || next == EligibilityForecastStatus.closed
            case .pending:
                return next == EligibilityForecastStatus.active || next == EligibilityForecastStatus.suspended
            case .active:
                return next == EligibilityForecastStatus.suspended || next == EligibilityForecastStatus.closed
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

        func moveTo(_ next: EligibilityForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedTotal() -> Double {
            return ((weight + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> EligibilityForecast {
            return EligibilityForecast(
                code: code,
                label: label,
                weight: weight,
                patientRef: patientRef,
                ward: ward,
                acuity: acuity,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a eligibility forecast in status draft.
    static func newEligibilityForecast(_ code: String, label: String) -> EligibilityForecast {
        return EligibilityForecast(
            code: code,
            label: label,
            weight: 0.0,
            patientRef: "",
            ward: "",
            acuity: 0,
            visible: false,
            status: EligibilityForecastStatus.draft
        )
    }
}
