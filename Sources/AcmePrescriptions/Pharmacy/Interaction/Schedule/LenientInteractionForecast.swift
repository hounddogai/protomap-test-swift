import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a lenient interaction forecast is in its life cycle.
    enum LenientInteractionForecastStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A lenient interaction forecast as the interaction team keeps it.
    final class LenientInteractionForecast {
        var code: String
        var label: String
        var region: String
        var capacity: Int
        var description: String
        var unit: String
        var bed: String
        var attempts: Int
        var status: LenientInteractionForecastStatus

        init(code: String, label: String, region: String, capacity: Int, description: String, unit: String, bed: String, attempts: Int, status: LenientInteractionForecastStatus) {
            self.code = code
            self.label = label
            self.region = region
            self.capacity = capacity
            self.description = description
            self.unit = unit
            self.bed = bed
            self.attempts = attempts
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

        func canMoveTo(_ next: LenientInteractionForecastStatus) -> Bool {
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
                return next == LenientInteractionForecastStatus.published || next == LenientInteractionForecastStatus.retired
            case .published:
                return next == LenientInteractionForecastStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientInteractionForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient interaction forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netLoad() -> Double {
            return ((Double(capacity) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> LenientInteractionForecast {
            return LenientInteractionForecast(
                code: code,
                label: label,
                region: region,
                capacity: capacity,
                description: description,
                unit: unit,
                bed: bed,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a lenient interaction forecast in status created.
    static func newLenientInteractionForecast(_ code: String, label: String) -> LenientInteractionForecast {
        return LenientInteractionForecast(
            code: code,
            label: label,
            region: "",
            capacity: 0,
            description: "",
            unit: "",
            bed: "",
            attempts: 0,
            status: LenientInteractionForecastStatus.created
        )
    }
}
