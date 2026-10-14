import AcmePlatform
import Foundation

extension Referrals {
    /// Where a seasonal network cycle is in its life cycle.
    enum SeasonalNetworkCycleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One seasonal network cycle, with what the planners need to act on it.
    final class SeasonalNetworkCycle {
        var code: String
        var name: String
        var ward: String
        var copay: Double
        var cost: Double
        var currency: String
        var encounterID: String
        var status: SeasonalNetworkCycleStatus

        init(code: String, name: String, ward: String, copay: Double, cost: Double, currency: String, encounterID: String, status: SeasonalNetworkCycleStatus) {
            self.code = code
            self.name = name
            self.ward = ward
            self.copay = copay
            self.cost = cost
            self.currency = currency
            self.encounterID = encounterID
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

        func canMoveTo(_ next: SeasonalNetworkCycleStatus) -> Bool {
            switch status {
            case .planned:
                return next == SeasonalNetworkCycleStatus.inProgress
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == SeasonalNetworkCycleStatus.completed || next == SeasonalNetworkCycleStatus.cancelled
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

        func moveTo(_ next: SeasonalNetworkCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal network cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("seasonal network cycle") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((cost - copay) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalNetworkCycle {
            return SeasonalNetworkCycle(
                code: code,
                name: name,
                ward: ward,
                copay: copay,
                cost: cost,
                currency: currency,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a seasonal network cycle in status planned.
    static func newSeasonalNetworkCycle(_ code: String, name: String) -> SeasonalNetworkCycle {
        return SeasonalNetworkCycle(
            code: code,
            name: name,
            ward: "",
            copay: 0.0,
            cost: 0.0,
            currency: "",
            encounterID: "",
            status: SeasonalNetworkCycleStatus.planned
        )
    }
}
