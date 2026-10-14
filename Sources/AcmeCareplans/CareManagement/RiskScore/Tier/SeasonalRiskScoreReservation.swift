import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a seasonal risk score reservation is in its life cycle.
    enum SeasonalRiskScoreReservationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A seasonal risk score reservation as the risk score team keeps it.
    final class SeasonalRiskScoreReservation {
        var code: String
        var label: String
        var facility: String
        var timezone: String
        var weight: Double
        var copay: Double
        var region: String
        var sequence: Int
        var phone: String
        var startsAt: Int
        var status: SeasonalRiskScoreReservationStatus

        init(code: String, label: String, facility: String, timezone: String, weight: Double, copay: Double, region: String, sequence: Int, phone: String, startsAt: Int, status: SeasonalRiskScoreReservationStatus) {
            self.code = code
            self.label = label
            self.facility = facility
            self.timezone = timezone
            self.weight = weight
            self.copay = copay
            self.region = region
            self.sequence = sequence
            self.phone = phone
            self.startsAt = startsAt
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

        func canMoveTo(_ next: SeasonalRiskScoreReservationStatus) -> Bool {
            switch status {
            case .planned:
                return next == SeasonalRiskScoreReservationStatus.scheduled || next == SeasonalRiskScoreReservationStatus.cancelled
            case .scheduled:
                return next == SeasonalRiskScoreReservationStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
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

        func moveTo(_ next: SeasonalRiskScoreReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal risk score reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("seasonal risk score reservation") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(startsAt) - weight) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalRiskScoreReservation {
            return SeasonalRiskScoreReservation(
                code: code,
                label: label,
                facility: facility,
                timezone: timezone,
                weight: weight,
                copay: copay,
                region: region,
                sequence: sequence,
                phone: phone,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a seasonal risk score reservation in status planned.
    static func newSeasonalRiskScoreReservation(_ code: String, label: String) -> SeasonalRiskScoreReservation {
        return SeasonalRiskScoreReservation(
            code: code,
            label: label,
            facility: "",
            timezone: "",
            weight: 0.0,
            copay: 0.0,
            region: "",
            sequence: 0,
            phone: "",
            startsAt: 0,
            status: SeasonalRiskScoreReservationStatus.planned
        )
    }
}
