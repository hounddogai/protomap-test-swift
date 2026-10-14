import AcmePlatform
import Foundation

extension Staffing {
    /// Where a adaptive acuity plan claim is in its life cycle.
    enum AdaptiveAcuityPlanClaimStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A adaptive acuity plan claim as the acuity plan team keeps it.
    final class AdaptiveAcuityPlanClaim {
        var code: String
        var title: String
        var threshold: Double
        var segment: String
        var specialty: String
        var diagnosisCode: String
        var startsAt: Int
        var visitMinutes: Int
        var payer: String
        var graceDays: Int
        var allergy: String
        var status: AdaptiveAcuityPlanClaimStatus

        init(code: String, title: String, threshold: Double, segment: String, specialty: String, diagnosisCode: String, startsAt: Int, visitMinutes: Int, payer: String, graceDays: Int, allergy: String, status: AdaptiveAcuityPlanClaimStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.segment = segment
            self.specialty = specialty
            self.diagnosisCode = diagnosisCode
            self.startsAt = startsAt
            self.visitMinutes = visitMinutes
            self.payer = payer
            self.graceDays = graceDays
            self.allergy = allergy
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

        func canMoveTo(_ next: AdaptiveAcuityPlanClaimStatus) -> Bool {
            switch status {
            case .draft:
                return next == AdaptiveAcuityPlanClaimStatus.active || next == AdaptiveAcuityPlanClaimStatus.suspended
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: AdaptiveAcuityPlanClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive acuity plan claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedExposure() -> Double {
            return ((Double(graceDays) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveAcuityPlanClaim {
            return AdaptiveAcuityPlanClaim(
                code: code,
                title: title,
                threshold: threshold,
                segment: segment,
                specialty: specialty,
                diagnosisCode: diagnosisCode,
                startsAt: startsAt,
                visitMinutes: visitMinutes,
                payer: payer,
                graceDays: graceDays,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a adaptive acuity plan claim in status draft.
    static func newAdaptiveAcuityPlanClaim(_ code: String, title: String) -> AdaptiveAcuityPlanClaim {
        return AdaptiveAcuityPlanClaim(
            code: code,
            title: title,
            threshold: 0.0,
            segment: "",
            specialty: "",
            diagnosisCode: "",
            startsAt: 0,
            visitMinutes: 0,
            payer: "",
            graceDays: 0,
            allergy: "",
            status: AdaptiveAcuityPlanClaimStatus.draft
        )
    }
}
