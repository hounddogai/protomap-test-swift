import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted formulary estimate is in its life cycle.
    enum WeightedFormularyEstimateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a weighted formulary estimate and its current status.
    final class WeightedFormularyEstimate {
        var code: String
        var label: String
        var approved: Bool
        var amount: Double
        var tags: [String]
        var quantity: Int
        var status: WeightedFormularyEstimateStatus

        init(code: String, label: String, approved: Bool, amount: Double, tags: [String], quantity: Int, status: WeightedFormularyEstimateStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.amount = amount
            self.tags = tags
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

        func canMoveTo(_ next: WeightedFormularyEstimateStatus) -> Bool {
            switch status {
            case .requested:
                return next == WeightedFormularyEstimateStatus.revoked
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == WeightedFormularyEstimateStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedFormularyEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted formulary estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedExposure() -> Double {
            return ((amount + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedFormularyEstimate {
            return WeightedFormularyEstimate(
                code: code,
                label: label,
                approved: approved,
                amount: amount,
                tags: tags,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted formulary estimate in status requested.
    static func newWeightedFormularyEstimate(_ code: String, label: String) -> WeightedFormularyEstimate {
        return WeightedFormularyEstimate(
            code: code,
            label: label,
            approved: false,
            amount: 0.0,
            tags: [],
            quantity: 0,
            status: WeightedFormularyEstimateStatus.requested
        )
    }
}
