import AcmePlatform
import Foundation

extension Staffing {
    /// Where a weighted acuity plan proposal is in its life cycle.
    enum WeightedAcuityPlanProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A weighted acuity plan proposal. Its code is unique within a tenant.
    final class WeightedAcuityPlanProposal {
        var code: String
        var label: String
        var unit: String
        var floorValue: Double
        var sequence: Int
        var cost: Double
        var title: String
        var payer: String
        var region: String
        var procedureCode: String
        var active: Bool
        var status: WeightedAcuityPlanProposalStatus

        init(code: String, label: String, unit: String, floorValue: Double, sequence: Int, cost: Double, title: String, payer: String, region: String, procedureCode: String, active: Bool, status: WeightedAcuityPlanProposalStatus) {
            self.code = code
            self.label = label
            self.unit = unit
            self.floorValue = floorValue
            self.sequence = sequence
            self.cost = cost
            self.title = title
            self.payer = payer
            self.region = region
            self.procedureCode = procedureCode
            self.active = active
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

        func canMoveTo(_ next: WeightedAcuityPlanProposalStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: WeightedAcuityPlanProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted acuity plan proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedValue() -> Double {
            return ((Double(sequence) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> WeightedAcuityPlanProposal {
            return WeightedAcuityPlanProposal(
                code: code,
                label: label,
                unit: unit,
                floorValue: floorValue,
                sequence: sequence,
                cost: cost,
                title: title,
                payer: payer,
                region: region,
                procedureCode: procedureCode,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a weighted acuity plan proposal in status open.
    static func newWeightedAcuityPlanProposal(_ code: String, label: String) -> WeightedAcuityPlanProposal {
        return WeightedAcuityPlanProposal(
            code: code,
            label: label,
            unit: "",
            floorValue: 0.0,
            sequence: 0,
            cost: 0.0,
            title: "",
            payer: "",
            region: "",
            procedureCode: "",
            active: false,
            status: WeightedAcuityPlanProposalStatus.`open`
        )
    }
}
