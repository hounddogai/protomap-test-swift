import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a pending remittance allocation is in its life cycle.
    enum PendingRemittanceAllocationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A pending remittance allocation. Its code is unique within a tenant.
    final class PendingRemittanceAllocation {
        var code: String
        var label: String
        var externalRef: String
        var retries: Int
        var source: String
        var country: String
        var locale: String
        var status: PendingRemittanceAllocationStatus

        init(code: String, label: String, externalRef: String, retries: Int, source: String, country: String, locale: String, status: PendingRemittanceAllocationStatus) {
            self.code = code
            self.label = label
            self.externalRef = externalRef
            self.retries = retries
            self.source = source
            self.country = country
            self.locale = locale
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

        func canMoveTo(_ next: PendingRemittanceAllocationStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PendingRemittanceAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending remittance allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return Double(retries)
        }

        func copyValue() -> PendingRemittanceAllocation {
            return PendingRemittanceAllocation(
                code: code,
                label: label,
                externalRef: externalRef,
                retries: retries,
                source: source,
                country: country,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a pending remittance allocation in status proposed.
    static func newPendingRemittanceAllocation(_ code: String, label: String) -> PendingRemittanceAllocation {
        return PendingRemittanceAllocation(
            code: code,
            label: label,
            externalRef: "",
            retries: 0,
            source: "",
            country: "",
            locale: "",
            status: PendingRemittanceAllocationStatus.proposed
        )
    }
}
