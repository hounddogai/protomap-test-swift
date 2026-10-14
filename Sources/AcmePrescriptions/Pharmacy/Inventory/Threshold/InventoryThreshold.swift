import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory threshold is in its life cycle.
    enum InventoryThresholdStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A inventory threshold. Its code is unique within a tenant.
    final class InventoryThreshold {
        var code: String
        var title: String
        var unit: String
        var currency: String
        var description: String
        var score: Double
        var status: InventoryThresholdStatus

        init(code: String, title: String, unit: String, currency: String, description: String, score: Double, status: InventoryThresholdStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.currency = currency
            self.description = description
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: InventoryThresholdStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == InventoryThresholdStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: InventoryThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> InventoryThreshold {
            return InventoryThreshold(
                code: code,
                title: title,
                unit: unit,
                currency: currency,
                description: description,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a inventory threshold in status created.
    static func newInventoryThreshold(_ code: String, title: String) -> InventoryThreshold {
        return InventoryThreshold(
            code: code,
            title: title,
            unit: "",
            currency: "",
            description: "",
            score: 0.0,
            status: InventoryThresholdStatus.created
        )
    }
}
