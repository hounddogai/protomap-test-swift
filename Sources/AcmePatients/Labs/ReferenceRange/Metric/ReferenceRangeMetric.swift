import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range metric is in its life cycle.
    enum ReferenceRangeMetricStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One reference range metric, with what the planners need to act on it.
    final class ReferenceRangeMetric {
        var code: String
        var label: String
        var quantity: Int
        var windowDays: Int
        var unit: String
        var status: ReferenceRangeMetricStatus

        init(code: String, label: String, quantity: Int, windowDays: Int, unit: String, status: ReferenceRangeMetricStatus) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.windowDays = windowDays
            self.unit = unit
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

        func canMoveTo(_ next: ReferenceRangeMetricStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ReferenceRangeMetricStatus.reopened
            case .inReview:
                return next == ReferenceRangeMetricStatus.reopened
            case .resolved:
                return next == ReferenceRangeMetricStatus.archived
            case .reopened:
                return next == ReferenceRangeMetricStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferenceRangeMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveValue() -> Double {
            return ((Double(quantity) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeMetric {
            return ReferenceRangeMetric(
                code: code,
                label: label,
                quantity: quantity,
                windowDays: windowDays,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a reference range metric in status open.
    static func newReferenceRangeMetric(_ code: String, label: String) -> ReferenceRangeMetric {
        return ReferenceRangeMetric(
            code: code,
            label: label,
            quantity: 0,
            windowDays: 0,
            unit: "",
            status: ReferenceRangeMetricStatus.`open`
        )
    }
}
