import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a regional alert metric is in its life cycle.
    enum RegionalAlertMetricStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One regional alert metric, with what the planners need to act on it.
    final class RegionalAlertMetric {
        var code: String
        var label: String
        var priority: Int
        var ratio: Double
        var category: String
        var status: RegionalAlertMetricStatus

        init(code: String, label: String, priority: Int, ratio: Double, category: String, status: RegionalAlertMetricStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.ratio = ratio
            self.category = category
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalAlertMetricStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RegionalAlertMetricStatus.reopened
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == RegionalAlertMetricStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalAlertMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional alert metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedVolume() -> Double {
            return ((ratio - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalAlertMetric {
            return RegionalAlertMetric(
                code: code,
                label: label,
                priority: priority,
                ratio: ratio,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a regional alert metric in status open.
    static func newRegionalAlertMetric(_ code: String, label: String) -> RegionalAlertMetric {
        return RegionalAlertMetric(
            code: code,
            label: label,
            priority: 0,
            ratio: 0.0,
            category: "",
            status: RegionalAlertMetricStatus.`open`
        )
    }
}
