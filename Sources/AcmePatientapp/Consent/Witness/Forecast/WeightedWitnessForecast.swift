import AcmePlatform
import Foundation

extension Consent {
    /// Where a weighted witness forecast is in its life cycle.
    enum WeightedWitnessForecastStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A weighted witness forecast. Its code is unique within a tenant.
    final class WeightedWitnessForecast {
        var code: String
        var title: String
        var quantity: Int
        var cost: Double
        var description: String
        var floorValue: Double
        var label: String
        var phone: String
        var notes: String
        var status: WeightedWitnessForecastStatus

        init(code: String, title: String, quantity: Int, cost: Double, description: String, floorValue: Double, label: String, phone: String, notes: String, status: WeightedWitnessForecastStatus) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.cost = cost
            self.description = description
            self.floorValue = floorValue
            self.label = label
            self.phone = phone
            self.notes = notes
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

        func canMoveTo(_ next: WeightedWitnessForecastStatus) -> Bool {
            switch status {
            case .planned:
                return next == WeightedWitnessForecastStatus.inProgress
            case .scheduled:
                return next == WeightedWitnessForecastStatus.inProgress || next == WeightedWitnessForecastStatus.cancelled
            case .inProgress:
                switch next {
                case .completed:
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

        func moveTo(_ next: WeightedWitnessForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted witness forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("weighted witness forecast") \(code)"
        }

        func weightedVolume() -> Double {
            return (floorValue * cost * 100).rounded() / 100
        }

        func copyValue() -> WeightedWitnessForecast {
            return WeightedWitnessForecast(
                code: code,
                title: title,
                quantity: quantity,
                cost: cost,
                description: description,
                floorValue: floorValue,
                label: label,
                phone: phone,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a weighted witness forecast in status planned.
    static func newWeightedWitnessForecast(_ code: String, title: String) -> WeightedWitnessForecast {
        return WeightedWitnessForecast(
            code: code,
            title: title,
            quantity: 0,
            cost: 0.0,
            description: "",
            floorValue: 0.0,
            label: "",
            phone: "",
            notes: "",
            status: WeightedWitnessForecastStatus.planned
        )
    }
}
