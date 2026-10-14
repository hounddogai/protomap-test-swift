import AcmePlatform
import Foundation

extension Referrals {
    /// Where a weighted eligibility slot is in its life cycle.
    enum WeightedEligibilitySlotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A weighted eligibility slot as the eligibility team keeps it.
    final class WeightedEligibilitySlot {
        var code: String
        var label: String
        var payer: String
        var locale: String
        var durationMinutes: Int
        var status: WeightedEligibilitySlotStatus

        init(code: String, label: String, payer: String, locale: String, durationMinutes: Int, status: WeightedEligibilitySlotStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.locale = locale
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: WeightedEligibilitySlotStatus) -> Bool {
            switch status {
            case .created:
                return next == WeightedEligibilitySlotStatus.validated || next == WeightedEligibilitySlotStatus.published
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

        func moveTo(_ next: WeightedEligibilitySlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted eligibility slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("weighted eligibility slot") \(code)"
        }

        func measuredValue() -> Double {
            return Double(durationMinutes)
        }

        func copyValue() -> WeightedEligibilitySlot {
            return WeightedEligibilitySlot(
                code: code,
                label: label,
                payer: payer,
                locale: locale,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a weighted eligibility slot in status created.
    static func newWeightedEligibilitySlot(_ code: String, label: String) -> WeightedEligibilitySlot {
        return WeightedEligibilitySlot(
            code: code,
            label: label,
            payer: "",
            locale: "",
            durationMinutes: 0,
            status: WeightedEligibilitySlotStatus.created
        )
    }
}
