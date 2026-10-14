import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a weighted bed board claim is in its life cycle.
    enum WeightedBedBoardClaimStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a weighted bed board claim and its current status.
    final class WeightedBedBoardClaim {
        var code: String
        var name: String
        var category: String
        var label: String
        var weight: Double
        var payer: String
        var amount: Double
        var attempts: Int
        var dosageMg: Double
        var sequence: Int
        var status: WeightedBedBoardClaimStatus

        init(code: String, name: String, category: String, label: String, weight: Double, payer: String, amount: Double, attempts: Int, dosageMg: Double, sequence: Int, status: WeightedBedBoardClaimStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.label = label
            self.weight = weight
            self.payer = payer
            self.amount = amount
            self.attempts = attempts
            self.dosageMg = dosageMg
            self.sequence = sequence
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

        func canMoveTo(_ next: WeightedBedBoardClaimStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == WeightedBedBoardClaimStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedBedBoardClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted bed board claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveExposure() -> Double {
            return ((weight - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedBedBoardClaim {
            return WeightedBedBoardClaim(
                code: code,
                name: name,
                category: category,
                label: label,
                weight: weight,
                payer: payer,
                amount: amount,
                attempts: attempts,
                dosageMg: dosageMg,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a weighted bed board claim in status proposed.
    static func newWeightedBedBoardClaim(_ code: String, name: String) -> WeightedBedBoardClaim {
        return WeightedBedBoardClaim(
            code: code,
            name: name,
            category: "",
            label: "",
            weight: 0.0,
            payer: "",
            amount: 0.0,
            attempts: 0,
            dosageMg: 0.0,
            sequence: 0,
            status: WeightedBedBoardClaimStatus.proposed
        )
    }
}
