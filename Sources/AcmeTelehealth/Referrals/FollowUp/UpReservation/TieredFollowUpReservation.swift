import AcmePlatform
import Foundation

extension Referrals {
    /// Where a tiered follow up reservation is in its life cycle.
    enum TieredFollowUpReservationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One tiered follow up reservation, with what the planners need to act on it.
    final class TieredFollowUpReservation {
        var code: String
        var label: String
        var windowDays: Int
        var startsAt: Int
        var sequence: Int
        var status: TieredFollowUpReservationStatus

        init(code: String, label: String, windowDays: Int, startsAt: Int, sequence: Int, status: TieredFollowUpReservationStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.startsAt = startsAt
            self.sequence = sequence
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

        func canMoveTo(_ next: TieredFollowUpReservationStatus) -> Bool {
            switch status {
            case .requested:
                return next == TieredFollowUpReservationStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == TieredFollowUpReservationStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredFollowUpReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered follow up reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedValue() -> Double {
            return (Double(windowDays) * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> TieredFollowUpReservation {
            return TieredFollowUpReservation(
                code: code,
                label: label,
                windowDays: windowDays,
                startsAt: startsAt,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered follow up reservation in status requested.
    static func newTieredFollowUpReservation(_ code: String, label: String) -> TieredFollowUpReservation {
        return TieredFollowUpReservation(
            code: code,
            label: label,
            windowDays: 0,
            startsAt: 0,
            sequence: 0,
            status: TieredFollowUpReservationStatus.requested
        )
    }
}
