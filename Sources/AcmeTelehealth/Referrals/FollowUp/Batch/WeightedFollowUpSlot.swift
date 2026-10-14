import AcmePlatform
import Foundation

extension Referrals {
    /// Where a weighted follow up slot is in its life cycle.
    enum WeightedFollowUpSlotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A weighted follow up slot. Its code is unique within a tenant.
    final class WeightedFollowUpSlot {
        var code: String
        var label: String
        var discount: Double
        var margin: Double
        var copay: Double
        var status: WeightedFollowUpSlotStatus

        init(code: String, label: String, discount: Double, margin: Double, copay: Double, status: WeightedFollowUpSlotStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.margin = margin
            self.copay = copay
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

        func canMoveTo(_ next: WeightedFollowUpSlotStatus) -> Bool {
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
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: WeightedFollowUpSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted follow up slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedVolume() -> Double {
            return ((discount + copay) * 100).rounded() / 100
        }

        func copyValue() -> WeightedFollowUpSlot {
            return WeightedFollowUpSlot(
                code: code,
                label: label,
                discount: discount,
                margin: margin,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted follow up slot in status created.
    static func newWeightedFollowUpSlot(_ code: String, label: String) -> WeightedFollowUpSlot {
        return WeightedFollowUpSlot(
            code: code,
            label: label,
            discount: 0.0,
            margin: 0.0,
            copay: 0.0,
            status: WeightedFollowUpSlotStatus.created
        )
    }
}
