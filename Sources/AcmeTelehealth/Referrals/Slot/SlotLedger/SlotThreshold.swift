import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot threshold is in its life cycle.
    enum SlotThresholdStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a slot threshold and its current status.
    final class SlotThreshold {
        var code: String
        var title: String
        var rate: Double
        var ward: String
        var encounterID: String
        var status: SlotThresholdStatus

        init(code: String, title: String, rate: Double, ward: String, encounterID: String, status: SlotThresholdStatus) {
            self.code = code
            self.title = title
            self.rate = rate
            self.ward = ward
            self.encounterID = encounterID
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

        func canMoveTo(_ next: SlotThresholdStatus) -> Bool {
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
                return next == SlotThresholdStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SlotThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return rate
        }

        func copyValue() -> SlotThreshold {
            return SlotThreshold(
                code: code,
                title: title,
                rate: rate,
                ward: ward,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a slot threshold in status proposed.
    static func newSlotThreshold(_ code: String, title: String) -> SlotThreshold {
        return SlotThreshold(
            code: code,
            title: title,
            rate: 0.0,
            ward: "",
            encounterID: "",
            status: SlotThresholdStatus.proposed
        )
    }
}
