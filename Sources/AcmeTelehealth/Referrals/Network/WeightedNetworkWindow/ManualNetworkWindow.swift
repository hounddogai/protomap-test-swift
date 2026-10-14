import AcmePlatform
import Foundation

extension Referrals {
    /// Where a manual network window is in its life cycle.
    enum ManualNetworkWindowStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A manual network window as the network team keeps it.
    final class ManualNetworkWindow {
        var code: String
        var label: String
        var procedureCode: String
        var title: String
        var minimum: Double
        var discount: Double
        var dosageMg: Double
        var status: ManualNetworkWindowStatus

        init(code: String, label: String, procedureCode: String, title: String, minimum: Double, discount: Double, dosageMg: Double, status: ManualNetworkWindowStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.title = title
            self.minimum = minimum
            self.discount = discount
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: ManualNetworkWindowStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == ManualNetworkWindowStatus.rejected
            case .rejected:
                return next == ManualNetworkWindowStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualNetworkWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual network window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netVolume() -> Double {
            return ((minimum + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> ManualNetworkWindow {
            return ManualNetworkWindow(
                code: code,
                label: label,
                procedureCode: procedureCode,
                title: title,
                minimum: minimum,
                discount: discount,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a manual network window in status proposed.
    static func newManualNetworkWindow(_ code: String, label: String) -> ManualNetworkWindow {
        return ManualNetworkWindow(
            code: code,
            label: label,
            procedureCode: "",
            title: "",
            minimum: 0.0,
            discount: 0.0,
            dosageMg: 0.0,
            status: ManualNetworkWindowStatus.proposed
        )
    }
}
