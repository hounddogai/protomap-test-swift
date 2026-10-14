import AcmePlatform
import Foundation

extension Consent {
    /// Where a seasonal revocation reservation is in its life cycle.
    enum SeasonalRevocationReservationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One seasonal revocation reservation, with what the planners need to act on it.
    final class SeasonalRevocationReservation {
        var code: String
        var title: String
        var cost: Double
        var summary: String
        var facility: String
        var acuity: Int
        var threshold: Double
        var status: SeasonalRevocationReservationStatus

        init(code: String, title: String, cost: Double, summary: String, facility: String, acuity: Int, threshold: Double, status: SeasonalRevocationReservationStatus) {
            self.code = code
            self.title = title
            self.cost = cost
            self.summary = summary
            self.facility = facility
            self.acuity = acuity
            self.threshold = threshold
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

        func canMoveTo(_ next: SeasonalRevocationReservationStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == SeasonalRevocationReservationStatus.inProgress
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: SeasonalRevocationReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal revocation reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("seasonal revocation reservation") \(code)"
        }

        func effectiveExposure() -> Double {
            return (threshold * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalRevocationReservation {
            return SeasonalRevocationReservation(
                code: code,
                title: title,
                cost: cost,
                summary: summary,
                facility: facility,
                acuity: acuity,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a seasonal revocation reservation in status planned.
    static func newSeasonalRevocationReservation(_ code: String, title: String) -> SeasonalRevocationReservation {
        return SeasonalRevocationReservation(
            code: code,
            title: title,
            cost: 0.0,
            summary: "",
            facility: "",
            acuity: 0,
            threshold: 0.0,
            status: SeasonalRevocationReservationStatus.planned
        )
    }
}
