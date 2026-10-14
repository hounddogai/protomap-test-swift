import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan claim is in its life cycle.
    enum AcuityPlanClaimStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a acuity plan claim and its current status.
    final class AcuityPlanClaim {
        var code: String
        var name: String
        var payer: String
        var weight: Double
        var dosageMg: Double
        var limit: Int
        var ownerID: String
        var status: AcuityPlanClaimStatus

        init(code: String, name: String, payer: String, weight: Double, dosageMg: Double, limit: Int, ownerID: String, status: AcuityPlanClaimStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.weight = weight
            self.dosageMg = dosageMg
            self.limit = limit
            self.ownerID = ownerID
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

        func canMoveTo(_ next: AcuityPlanClaimStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == AcuityPlanClaimStatus.inProgress || next == AcuityPlanClaimStatus.cancelled
            case .inProgress:
                return next == AcuityPlanClaimStatus.completed || next == AcuityPlanClaimStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: AcuityPlanClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedTotal() -> Double {
            return ((dosageMg + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanClaim {
            return AcuityPlanClaim(
                code: code,
                name: name,
                payer: payer,
                weight: weight,
                dosageMg: dosageMg,
                limit: limit,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a acuity plan claim in status planned.
    static func newAcuityPlanClaim(_ code: String, name: String) -> AcuityPlanClaim {
        return AcuityPlanClaim(
            code: code,
            name: name,
            payer: "",
            weight: 0.0,
            dosageMg: 0.0,
            limit: 0,
            ownerID: "",
            status: AcuityPlanClaimStatus.planned
        )
    }
}
