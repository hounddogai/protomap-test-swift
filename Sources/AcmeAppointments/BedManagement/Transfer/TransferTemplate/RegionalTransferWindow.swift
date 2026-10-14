import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a regional transfer window is in its life cycle.
    enum RegionalTransferWindowStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A regional transfer window as the transfer team keeps it.
    final class RegionalTransferWindow {
        var code: String
        var title: String
        var label: String
        var category: String
        var region: String
        var payer: String
        var amount: Double
        var status: RegionalTransferWindowStatus

        init(code: String, title: String, label: String, category: String, region: String, payer: String, amount: Double, status: RegionalTransferWindowStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.category = category
            self.region = region
            self.payer = payer
            self.amount = amount
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

        func canMoveTo(_ next: RegionalTransferWindowStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RegionalTransferWindowStatus.rejected
            case .approved:
                return next == RegionalTransferWindowStatus.rejected
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

        func moveTo(_ next: RegionalTransferWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional transfer window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> RegionalTransferWindow {
            return RegionalTransferWindow(
                code: code,
                title: title,
                label: label,
                category: category,
                region: region,
                payer: payer,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a regional transfer window in status proposed.
    static func newRegionalTransferWindow(_ code: String, title: String) -> RegionalTransferWindow {
        return RegionalTransferWindow(
            code: code,
            title: title,
            label: "",
            category: "",
            region: "",
            payer: "",
            amount: 0.0,
            status: RegionalTransferWindowStatus.proposed
        )
    }
}
