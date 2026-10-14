import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool score is in its life cycle.
    enum FloatPoolScoreStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a float pool score and its current status.
    final class FloatPoolScore {
        var code: String
        var label: String
        var cost: Double
        var externalRef: String
        var floorValue: Double
        var payer: String
        var clinicianID: String
        var dosageMg: Double
        var allergy: String
        var status: FloatPoolScoreStatus

        init(code: String, label: String, cost: Double, externalRef: String, floorValue: Double, payer: String, clinicianID: String, dosageMg: Double, allergy: String, status: FloatPoolScoreStatus) {
            self.code = code
            self.label = label
            self.cost = cost
            self.externalRef = externalRef
            self.floorValue = floorValue
            self.payer = payer
            self.clinicianID = clinicianID
            self.dosageMg = dosageMg
            self.allergy = allergy
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

        func canMoveTo(_ next: FloatPoolScoreStatus) -> Bool {
            switch status {
            case .proposed:
                return next == FloatPoolScoreStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: FloatPoolScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("float pool score") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((dosageMg + cost) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolScore {
            return FloatPoolScore(
                code: code,
                label: label,
                cost: cost,
                externalRef: externalRef,
                floorValue: floorValue,
                payer: payer,
                clinicianID: clinicianID,
                dosageMg: dosageMg,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a float pool score in status proposed.
    static func newFloatPoolScore(_ code: String, label: String) -> FloatPoolScore {
        return FloatPoolScore(
            code: code,
            label: label,
            cost: 0.0,
            externalRef: "",
            floorValue: 0.0,
            payer: "",
            clinicianID: "",
            dosageMg: 0.0,
            allergy: "",
            status: FloatPoolScoreStatus.proposed
        )
    }
}
