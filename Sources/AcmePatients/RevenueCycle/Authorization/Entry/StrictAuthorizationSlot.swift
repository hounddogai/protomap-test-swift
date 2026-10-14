import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a strict authorization slot is in its life cycle.
    enum StrictAuthorizationSlotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a strict authorization slot and its current status.
    final class StrictAuthorizationSlot {
        var code: String
        var title: String
        var quantity: Int
        var payer: String
        var archived: Bool
        var status: StrictAuthorizationSlotStatus

        init(code: String, title: String, quantity: Int, payer: String, archived: Bool, status: StrictAuthorizationSlotStatus) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.payer = payer
            self.archived = archived
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

        func canMoveTo(_ next: StrictAuthorizationSlotStatus) -> Bool {
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
                case .published, .retired:
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

        func moveTo(_ next: StrictAuthorizationSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict authorization slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> StrictAuthorizationSlot {
            return StrictAuthorizationSlot(
                code: code,
                title: title,
                quantity: quantity,
                payer: payer,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a strict authorization slot in status created.
    static func newStrictAuthorizationSlot(_ code: String, title: String) -> StrictAuthorizationSlot {
        return StrictAuthorizationSlot(
            code: code,
            title: title,
            quantity: 0,
            payer: "",
            archived: false,
            status: StrictAuthorizationSlotStatus.created
        )
    }
}
