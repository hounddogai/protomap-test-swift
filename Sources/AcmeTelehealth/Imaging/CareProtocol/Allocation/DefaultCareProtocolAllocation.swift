import AcmePlatform
import Foundation

extension Imaging {
    /// Where a default care protocol allocation is in its life cycle.
    enum DefaultCareProtocolAllocationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a default care protocol allocation and its current status.
    final class DefaultCareProtocolAllocation {
        var code: String
        var title: String
        var diagnosisCode: String
        var quantity: Int
        var capacity: Int
        var refills: Int
        var status: DefaultCareProtocolAllocationStatus

        init(code: String, title: String, diagnosisCode: String, quantity: Int, capacity: Int, refills: Int, status: DefaultCareProtocolAllocationStatus) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.quantity = quantity
            self.capacity = capacity
            self.refills = refills
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultCareProtocolAllocationStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == DefaultCareProtocolAllocationStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultCareProtocolAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default care protocol allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveValue() -> Double {
            return ((Double(capacity) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultCareProtocolAllocation {
            return DefaultCareProtocolAllocation(
                code: code,
                title: title,
                diagnosisCode: diagnosisCode,
                quantity: quantity,
                capacity: capacity,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default care protocol allocation in status requested.
    static func newDefaultCareProtocolAllocation(_ code: String, title: String) -> DefaultCareProtocolAllocation {
        return DefaultCareProtocolAllocation(
            code: code,
            title: title,
            diagnosisCode: "",
            quantity: 0,
            capacity: 0,
            refills: 0,
            status: DefaultCareProtocolAllocationStatus.requested
        )
    }
}
