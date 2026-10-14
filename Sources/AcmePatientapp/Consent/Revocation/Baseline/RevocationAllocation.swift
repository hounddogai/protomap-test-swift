import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation allocation is in its life cycle.
    enum RevocationAllocationStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A revocation allocation as the revocation team keeps it.
    final class RevocationAllocation {
        var code: String
        var label: String
        var contactEmail: String
        var visitMinutes: Int
        var ward: String
        var phone: String
        var status: RevocationAllocationStatus

        init(code: String, label: String, contactEmail: String, visitMinutes: Int, ward: String, phone: String, status: RevocationAllocationStatus) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.visitMinutes = visitMinutes
            self.ward = ward
            self.phone = phone
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

        func canMoveTo(_ next: RevocationAllocationStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == RevocationAllocationStatus.draining || next == RevocationAllocationStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: RevocationAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("revocation allocation") \(code)"
        }

        func measuredValue() -> Double {
            return Double(visitMinutes)
        }

        func copyValue() -> RevocationAllocation {
            return RevocationAllocation(
                code: code,
                label: label,
                contactEmail: contactEmail,
                visitMinutes: visitMinutes,
                ward: ward,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a revocation allocation in status idle.
    static func newRevocationAllocation(_ code: String, label: String) -> RevocationAllocation {
        return RevocationAllocation(
            code: code,
            label: label,
            contactEmail: "",
            visitMinutes: 0,
            ward: "",
            phone: "",
            status: RevocationAllocationStatus.idle
        )
    }
}
