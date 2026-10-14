import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness adjustment is in its life cycle.
    enum WitnessAdjustmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A witness adjustment as the witness team keeps it.
    final class WitnessAdjustment {
        var code: String
        var title: String
        var active: Bool
        var startsAt: Int
        var endsAt: Int
        var channel: String
        var encounterID: String
        var copay: Double
        var discount: Double
        var durationMinutes: Int
        var status: WitnessAdjustmentStatus

        init(code: String, title: String, active: Bool, startsAt: Int, endsAt: Int, channel: String, encounterID: String, copay: Double, discount: Double, durationMinutes: Int, status: WitnessAdjustmentStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.startsAt = startsAt
            self.endsAt = endsAt
            self.channel = channel
            self.encounterID = encounterID
            self.copay = copay
            self.discount = discount
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: WitnessAdjustmentStatus) -> Bool {
            switch status {
            case .`open`:
                return next == WitnessAdjustmentStatus.reopened
            case .inReview:
                return next == WitnessAdjustmentStatus.reopened
            case .resolved:
                return next == WitnessAdjustmentStatus.reopened
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

        func moveTo(_ next: WitnessAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedValue() -> Double {
            return ((copay + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> WitnessAdjustment {
            return WitnessAdjustment(
                code: code,
                title: title,
                active: active,
                startsAt: startsAt,
                endsAt: endsAt,
                channel: channel,
                encounterID: encounterID,
                copay: copay,
                discount: discount,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a witness adjustment in status open.
    static func newWitnessAdjustment(_ code: String, title: String) -> WitnessAdjustment {
        return WitnessAdjustment(
            code: code,
            title: title,
            active: false,
            startsAt: 0,
            endsAt: 0,
            channel: "",
            encounterID: "",
            copay: 0.0,
            discount: 0.0,
            durationMinutes: 0,
            status: WitnessAdjustmentStatus.`open`
        )
    }
}
