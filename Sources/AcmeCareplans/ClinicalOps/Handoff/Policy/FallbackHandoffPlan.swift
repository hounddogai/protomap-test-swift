import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a fallback handoff plan is in its life cycle.
    enum FallbackHandoffPlanStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A fallback handoff plan as the handoff team keeps it.
    final class FallbackHandoffPlan {
        var code: String
        var title: String
        var rate: Double
        var ownerID: String
        var segment: String
        var margin: Double
        var currency: String
        var diagnosisCode: String
        var patientRef: String
        var quantity: Int
        var status: FallbackHandoffPlanStatus

        init(code: String, title: String, rate: Double, ownerID: String, segment: String, margin: Double, currency: String, diagnosisCode: String, patientRef: String, quantity: Int, status: FallbackHandoffPlanStatus) {
            self.code = code
            self.title = title
            self.rate = rate
            self.ownerID = ownerID
            self.segment = segment
            self.margin = margin
            self.currency = currency
            self.diagnosisCode = diagnosisCode
            self.patientRef = patientRef
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackHandoffPlanStatus) -> Bool {
            switch status {
            case .requested:
                return next == FallbackHandoffPlanStatus.revoked || next == FallbackHandoffPlanStatus.expired
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == FallbackHandoffPlanStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackHandoffPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback handoff plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedLoad() -> Double {
            return (margin * rate * 100).rounded() / 100
        }

        func copyValue() -> FallbackHandoffPlan {
            return FallbackHandoffPlan(
                code: code,
                title: title,
                rate: rate,
                ownerID: ownerID,
                segment: segment,
                margin: margin,
                currency: currency,
                diagnosisCode: diagnosisCode,
                patientRef: patientRef,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a fallback handoff plan in status requested.
    static func newFallbackHandoffPlan(_ code: String, title: String) -> FallbackHandoffPlan {
        return FallbackHandoffPlan(
            code: code,
            title: title,
            rate: 0.0,
            ownerID: "",
            segment: "",
            margin: 0.0,
            currency: "",
            diagnosisCode: "",
            patientRef: "",
            quantity: 0,
            status: FallbackHandoffPlanStatus.requested
        )
    }
}
