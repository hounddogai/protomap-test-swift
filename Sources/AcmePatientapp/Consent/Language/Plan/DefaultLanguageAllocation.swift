import AcmePlatform
import Foundation

extension Consent {
    /// Where a default language allocation is in its life cycle.
    enum DefaultLanguageAllocationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A default language allocation. Its code is unique within a tenant.
    final class DefaultLanguageAllocation {
        var code: String
        var name: String
        var limit: Int
        var sequence: Int
        var createdAt: Int
        var status: DefaultLanguageAllocationStatus

        init(code: String, name: String, limit: Int, sequence: Int, createdAt: Int, status: DefaultLanguageAllocationStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.sequence = sequence
            self.createdAt = createdAt
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

        func canMoveTo(_ next: DefaultLanguageAllocationStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == DefaultLanguageAllocationStatus.rejected || next == DefaultLanguageAllocationStatus.withdrawn
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

        func moveTo(_ next: DefaultLanguageAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default language allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("default language allocation") \(code)"
        }

        func projectedLoad() -> Double {
            return ((Double(limit) - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultLanguageAllocation {
            return DefaultLanguageAllocation(
                code: code,
                name: name,
                limit: limit,
                sequence: sequence,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default language allocation in status proposed.
    static func newDefaultLanguageAllocation(_ code: String, name: String) -> DefaultLanguageAllocation {
        return DefaultLanguageAllocation(
            code: code,
            name: name,
            limit: 0,
            sequence: 0,
            createdAt: 0,
            status: DefaultLanguageAllocationStatus.proposed
        )
    }
}
