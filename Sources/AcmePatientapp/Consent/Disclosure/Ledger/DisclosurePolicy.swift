import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure policy is in its life cycle.
    enum DisclosurePolicyStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A disclosure policy. Its code is unique within a tenant.
    final class DisclosurePolicy {
        var code: String
        var name: String
        var procedureCode: String
        var segment: String
        var capacity: Int
        var status: DisclosurePolicyStatus

        init(code: String, name: String, procedureCode: String, segment: String, capacity: Int, status: DisclosurePolicyStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.segment = segment
            self.capacity = capacity
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

        func canMoveTo(_ next: DisclosurePolicyStatus) -> Bool {
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
                return next == DisclosurePolicyStatus.rejected || next == DisclosurePolicyStatus.withdrawn
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

        func moveTo(_ next: DisclosurePolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return Double(capacity)
        }

        func copyValue() -> DisclosurePolicy {
            return DisclosurePolicy(
                code: code,
                name: name,
                procedureCode: procedureCode,
                segment: segment,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a disclosure policy in status proposed.
    static func newDisclosurePolicy(_ code: String, name: String) -> DisclosurePolicy {
        return DisclosurePolicy(
            code: code,
            name: name,
            procedureCode: "",
            segment: "",
            capacity: 0,
            status: DisclosurePolicyStatus.proposed
        )
    }
}
