import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a regional risk score reservation is in its life cycle.
    enum RegionalRiskScoreReservationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A regional risk score reservation as the risk score team keeps it.
    final class RegionalRiskScoreReservation {
        var code: String
        var name: String
        var encounterID: String
        var graceDays: Int
        var expiresAt: Int
        var createdAt: Int
        var segment: String
        var status: RegionalRiskScoreReservationStatus

        init(code: String, name: String, encounterID: String, graceDays: Int, expiresAt: Int, createdAt: Int, segment: String, status: RegionalRiskScoreReservationStatus) {
            self.code = code
            self.name = name
            self.encounterID = encounterID
            self.graceDays = graceDays
            self.expiresAt = expiresAt
            self.createdAt = createdAt
            self.segment = segment
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

        func canMoveTo(_ next: RegionalRiskScoreReservationStatus) -> Bool {
            switch status {
            case .planned:
                return next == RegionalRiskScoreReservationStatus.inProgress
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == RegionalRiskScoreReservationStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalRiskScoreReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional risk score reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netValue() -> Double {
            return (Double(expiresAt) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> RegionalRiskScoreReservation {
            return RegionalRiskScoreReservation(
                code: code,
                name: name,
                encounterID: encounterID,
                graceDays: graceDays,
                expiresAt: expiresAt,
                createdAt: createdAt,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a regional risk score reservation in status planned.
    static func newRegionalRiskScoreReservation(_ code: String, name: String) -> RegionalRiskScoreReservation {
        return RegionalRiskScoreReservation(
            code: code,
            name: name,
            encounterID: "",
            graceDays: 0,
            expiresAt: 0,
            createdAt: 0,
            segment: "",
            status: RegionalRiskScoreReservationStatus.planned
        )
    }
}
