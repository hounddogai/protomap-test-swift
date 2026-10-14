import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a legacy isolation forecast is in its life cycle.
    enum LegacyIsolationForecastStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A legacy isolation forecast as the isolation team keeps it.
    final class LegacyIsolationForecast {
        var code: String
        var name: String
        var encounterID: String
        var updatedAt: Int
        var visible: Bool
        var minimum: Double
        var threshold: Double
        var weight: Double
        var floorValue: Double
        var cost: Double
        var checksum: String
        var status: LegacyIsolationForecastStatus

        init(code: String, name: String, encounterID: String, updatedAt: Int, visible: Bool, minimum: Double, threshold: Double, weight: Double, floorValue: Double, cost: Double, checksum: String, status: LegacyIsolationForecastStatus) {
            self.code = code
            self.name = name
            self.encounterID = encounterID
            self.updatedAt = updatedAt
            self.visible = visible
            self.minimum = minimum
            self.threshold = threshold
            self.weight = weight
            self.floorValue = floorValue
            self.cost = cost
            self.checksum = checksum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyIsolationForecastStatus) -> Bool {
            switch status {
            case .draft:
                return next == LegacyIsolationForecastStatus.pending || next == LegacyIsolationForecastStatus.closed
            case .pending:
                return next == LegacyIsolationForecastStatus.closed
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: LegacyIsolationForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy isolation forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedTotal() -> Double {
            return ((threshold + weight) * 100).rounded() / 100
        }

        func copyValue() -> LegacyIsolationForecast {
            return LegacyIsolationForecast(
                code: code,
                name: name,
                encounterID: encounterID,
                updatedAt: updatedAt,
                visible: visible,
                minimum: minimum,
                threshold: threshold,
                weight: weight,
                floorValue: floorValue,
                cost: cost,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a legacy isolation forecast in status draft.
    static func newLegacyIsolationForecast(_ code: String, name: String) -> LegacyIsolationForecast {
        return LegacyIsolationForecast(
            code: code,
            name: name,
            encounterID: "",
            updatedAt: 0,
            visible: false,
            minimum: 0.0,
            threshold: 0.0,
            weight: 0.0,
            floorValue: 0.0,
            cost: 0.0,
            checksum: "",
            status: LegacyIsolationForecastStatus.draft
        )
    }
}
