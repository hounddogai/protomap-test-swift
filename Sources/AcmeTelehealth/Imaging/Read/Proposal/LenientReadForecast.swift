import AcmePlatform
import Foundation

extension Imaging {
    /// Where a lenient read forecast is in its life cycle.
    enum LenientReadForecastStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A lenient read forecast as the read team keeps it.
    final class LenientReadForecast {
        var code: String
        var label: String
        var sequence: Int
        var visible: Bool
        var active: Bool
        var status: LenientReadForecastStatus

        init(code: String, label: String, sequence: Int, visible: Bool, active: Bool, status: LenientReadForecastStatus) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.visible = visible
            self.active = active
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

        func canMoveTo(_ next: LenientReadForecastStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LenientReadForecastStatus.reopened
            case .inReview:
                return next == LenientReadForecastStatus.resolved || next == LenientReadForecastStatus.reopened
            case .resolved:
                return next == LenientReadForecastStatus.reopened || next == LenientReadForecastStatus.archived
            case .reopened:
                return next == LenientReadForecastStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientReadForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient read forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return Double(sequence)
        }

        func copyValue() -> LenientReadForecast {
            return LenientReadForecast(
                code: code,
                label: label,
                sequence: sequence,
                visible: visible,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient read forecast in status open.
    static func newLenientReadForecast(_ code: String, label: String) -> LenientReadForecast {
        return LenientReadForecast(
            code: code,
            label: label,
            sequence: 0,
            visible: false,
            active: false,
            status: LenientReadForecastStatus.`open`
        )
    }
}
