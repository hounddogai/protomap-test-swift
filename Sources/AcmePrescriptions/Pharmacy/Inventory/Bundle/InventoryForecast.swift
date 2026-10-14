import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory forecast is in its life cycle.
    enum InventoryForecastStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A inventory forecast. Its code is unique within a tenant.
    final class InventoryForecast {
        var code: String
        var label: String
        var pinned: Bool
        var checksum: String
        var name: String
        var score: Double
        var status: InventoryForecastStatus

        init(code: String, label: String, pinned: Bool, checksum: String, name: String, score: Double, status: InventoryForecastStatus) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.checksum = checksum
            self.name = name
            self.score = score
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

        func canMoveTo(_ next: InventoryForecastStatus) -> Bool {
            switch status {
            case .proposed:
                return next == InventoryForecastStatus.approved || next == InventoryForecastStatus.rejected
            case .approved:
                return next == InventoryForecastStatus.rejected
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: InventoryForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> InventoryForecast {
            return InventoryForecast(
                code: code,
                label: label,
                pinned: pinned,
                checksum: checksum,
                name: name,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a inventory forecast in status proposed.
    static func newInventoryForecast(_ code: String, label: String) -> InventoryForecast {
        return InventoryForecast(
            code: code,
            label: label,
            pinned: false,
            checksum: "",
            name: "",
            score: 0.0,
            status: InventoryForecastStatus.proposed
        )
    }
}
