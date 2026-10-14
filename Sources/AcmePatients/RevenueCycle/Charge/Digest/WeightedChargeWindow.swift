import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a weighted charge window is in its life cycle.
    enum WeightedChargeWindowStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A weighted charge window. Its code is unique within a tenant.
    final class WeightedChargeWindow {
        var code: String
        var title: String
        var locale: String
        var label: String
        var copay: Double
        var status: WeightedChargeWindowStatus

        init(code: String, title: String, locale: String, label: String, copay: Double, status: WeightedChargeWindowStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.label = label
            self.copay = copay
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

        func canMoveTo(_ next: WeightedChargeWindowStatus) -> Bool {
            switch status {
            case .draft:
                return next == WeightedChargeWindowStatus.active || next == WeightedChargeWindowStatus.closed
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == WeightedChargeWindowStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedChargeWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted charge window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> WeightedChargeWindow {
            return WeightedChargeWindow(
                code: code,
                title: title,
                locale: locale,
                label: label,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a weighted charge window in status draft.
    static func newWeightedChargeWindow(_ code: String, title: String) -> WeightedChargeWindow {
        return WeightedChargeWindow(
            code: code,
            title: title,
            locale: "",
            label: "",
            copay: 0.0,
            status: WeightedChargeWindowStatus.draft
        )
    }
}
