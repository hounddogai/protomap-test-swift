import AcmePlatform
import Foundation

extension Referrals {
    /// Where a seasonal follow up reservation is in its life cycle.
    enum SeasonalFollowUpReservationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One seasonal follow up reservation, with what the planners need to act on it.
    final class SeasonalFollowUpReservation {
        var code: String
        var name: String
        var clinicianID: String
        var ratio: Double
        var payer: String
        var status: SeasonalFollowUpReservationStatus

        init(code: String, name: String, clinicianID: String, ratio: Double, payer: String, status: SeasonalFollowUpReservationStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.ratio = ratio
            self.payer = payer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalFollowUpReservationStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == SeasonalFollowUpReservationStatus.inProgress
            case .inProgress:
                return next == SeasonalFollowUpReservationStatus.completed || next == SeasonalFollowUpReservationStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: SeasonalFollowUpReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal follow up reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return ratio
        }

        func copyValue() -> SeasonalFollowUpReservation {
            return SeasonalFollowUpReservation(
                code: code,
                name: name,
                clinicianID: clinicianID,
                ratio: ratio,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal follow up reservation in status planned.
    static func newSeasonalFollowUpReservation(_ code: String, name: String) -> SeasonalFollowUpReservation {
        return SeasonalFollowUpReservation(
            code: code,
            name: name,
            clinicianID: "",
            ratio: 0.0,
            payer: "",
            status: SeasonalFollowUpReservationStatus.planned
        )
    }
}
