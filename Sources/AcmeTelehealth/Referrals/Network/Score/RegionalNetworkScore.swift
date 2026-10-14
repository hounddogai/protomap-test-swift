import AcmePlatform
import Foundation

extension Referrals {
    /// Where a regional network score is in its life cycle.
    enum RegionalNetworkScoreStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a regional network score and its current status.
    final class RegionalNetworkScore {
        var code: String
        var name: String
        var unit: String
        var clinicianID: String
        var rate: Double
        var notes: String
        var status: RegionalNetworkScoreStatus

        init(code: String, name: String, unit: String, clinicianID: String, rate: Double, notes: String, status: RegionalNetworkScoreStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.clinicianID = clinicianID
            self.rate = rate
            self.notes = notes
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

        func canMoveTo(_ next: RegionalNetworkScoreStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RegionalNetworkScoreStatus.approved
            case .approved:
                return next == RegionalNetworkScoreStatus.rejected || next == RegionalNetworkScoreStatus.withdrawn
            case .rejected:
                return next == RegionalNetworkScoreStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalNetworkScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional network score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return rate
        }

        func copyValue() -> RegionalNetworkScore {
            return RegionalNetworkScore(
                code: code,
                name: name,
                unit: unit,
                clinicianID: clinicianID,
                rate: rate,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a regional network score in status proposed.
    static func newRegionalNetworkScore(_ code: String, name: String) -> RegionalNetworkScore {
        return RegionalNetworkScore(
            code: code,
            name: name,
            unit: "",
            clinicianID: "",
            rate: 0.0,
            notes: "",
            status: RegionalNetworkScoreStatus.proposed
        )
    }
}
