import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a adaptive inventory score is in its life cycle.
    enum AdaptiveInventoryScoreStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A adaptive inventory score as the inventory team keeps it.
    final class AdaptiveInventoryScore {
        var code: String
        var label: String
        var name: String
        var acuity: Int
        var quantity: Int
        var status: AdaptiveInventoryScoreStatus

        init(code: String, label: String, name: String, acuity: Int, quantity: Int, status: AdaptiveInventoryScoreStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.acuity = acuity
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveInventoryScoreStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == AdaptiveInventoryScoreStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: AdaptiveInventoryScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive inventory score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedVolume() -> Double {
            return ((Double(quantity) + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveInventoryScore {
            return AdaptiveInventoryScore(
                code: code,
                label: label,
                name: name,
                acuity: acuity,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive inventory score in status created.
    static func newAdaptiveInventoryScore(_ code: String, label: String) -> AdaptiveInventoryScore {
        return AdaptiveInventoryScore(
            code: code,
            label: label,
            name: "",
            acuity: 0,
            quantity: 0,
            status: AdaptiveInventoryScoreStatus.created
        )
    }
}
