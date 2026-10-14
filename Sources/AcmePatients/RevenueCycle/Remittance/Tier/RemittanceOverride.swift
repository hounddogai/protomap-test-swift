import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance override is in its life cycle.
    enum RemittanceOverrideStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A remittance override as the remittance team keeps it.
    final class RemittanceOverride {
        var code: String
        var label: String
        var weight: Double
        var visitMinutes: Int
        var minimum: Double
        var encounterID: String
        var quantity: Int
        var discount: Double
        var status: RemittanceOverrideStatus

        init(code: String, label: String, weight: Double, visitMinutes: Int, minimum: Double, encounterID: String, quantity: Int, discount: Double, status: RemittanceOverrideStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.visitMinutes = visitMinutes
            self.minimum = minimum
            self.encounterID = encounterID
            self.quantity = quantity
            self.discount = discount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RemittanceOverrideStatus) -> Bool {
            switch status {
            case .idle:
                return next == RemittanceOverrideStatus.warming
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == RemittanceOverrideStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RemittanceOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netTotal() -> Double {
            return ((Double(quantity) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceOverride {
            return RemittanceOverride(
                code: code,
                label: label,
                weight: weight,
                visitMinutes: visitMinutes,
                minimum: minimum,
                encounterID: encounterID,
                quantity: quantity,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a remittance override in status idle.
    static func newRemittanceOverride(_ code: String, label: String) -> RemittanceOverride {
        return RemittanceOverride(
            code: code,
            label: label,
            weight: 0.0,
            visitMinutes: 0,
            minimum: 0.0,
            encounterID: "",
            quantity: 0,
            discount: 0.0,
            status: RemittanceOverrideStatus.idle
        )
    }
}
