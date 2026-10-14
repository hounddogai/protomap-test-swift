import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure forecast is in its life cycle.
    enum DisclosureForecastStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A disclosure forecast. Its code is unique within a tenant.
    final class DisclosureForecast {
        var code: String
        var title: String
        var category: String
        var weight: Double
        var windowDays: Int
        var pinned: Bool
        var margin: Double
        var label: String
        var status: DisclosureForecastStatus

        init(code: String, title: String, category: String, weight: Double, windowDays: Int, pinned: Bool, margin: Double, label: String, status: DisclosureForecastStatus) {
            self.code = code
            self.title = title
            self.category = category
            self.weight = weight
            self.windowDays = windowDays
            self.pinned = pinned
            self.margin = margin
            self.label = label
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

        func canMoveTo(_ next: DisclosureForecastStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == DisclosureForecastStatus.completed
            case .completed:
                return next == DisclosureForecastStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DisclosureForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func projectedVolume() -> Double {
            return ((Double(windowDays) + weight) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureForecast {
            return DisclosureForecast(
                code: code,
                title: title,
                category: category,
                weight: weight,
                windowDays: windowDays,
                pinned: pinned,
                margin: margin,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a disclosure forecast in status planned.
    static func newDisclosureForecast(_ code: String, title: String) -> DisclosureForecast {
        return DisclosureForecast(
            code: code,
            title: title,
            category: "",
            weight: 0.0,
            windowDays: 0,
            pinned: false,
            margin: 0.0,
            label: "",
            status: DisclosureForecastStatus.planned
        )
    }
}
