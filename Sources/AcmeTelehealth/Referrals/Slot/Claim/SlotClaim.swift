import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot claim is in its life cycle.
    enum SlotClaimStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One slot claim, with what the planners need to act on it.
    final class SlotClaim {
        var code: String
        var title: String
        var ratio: Double
        var copay: Double
        var budget: Double
        var facility: String
        var status: SlotClaimStatus

        init(code: String, title: String, ratio: Double, copay: Double, budget: Double, facility: String, status: SlotClaimStatus) {
            self.code = code
            self.title = title
            self.ratio = ratio
            self.copay = copay
            self.budget = budget
            self.facility = facility
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

        func canMoveTo(_ next: SlotClaimStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
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
                return next == SlotClaimStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SlotClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedValue() -> Double {
            return (ratio * copay * 100).rounded() / 100
        }

        func copyValue() -> SlotClaim {
            return SlotClaim(
                code: code,
                title: title,
                ratio: ratio,
                copay: copay,
                budget: budget,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a slot claim in status proposed.
    static func newSlotClaim(_ code: String, title: String) -> SlotClaim {
        return SlotClaim(
            code: code,
            title: title,
            ratio: 0.0,
            copay: 0.0,
            budget: 0.0,
            facility: "",
            status: SlotClaimStatus.proposed
        )
    }
}
