import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a default remittance digest is in its life cycle.
    enum DefaultRemittanceDigestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A default remittance digest. Its code is unique within a tenant.
    final class DefaultRemittanceDigest {
        var code: String
        var name: String
        var notes: String
        var active: Bool
        var limit: Int
        var quantity: Int
        var status: DefaultRemittanceDigestStatus

        init(code: String, name: String, notes: String, active: Bool, limit: Int, quantity: Int, status: DefaultRemittanceDigestStatus) {
            self.code = code
            self.name = name
            self.notes = notes
            self.active = active
            self.limit = limit
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultRemittanceDigestStatus) -> Bool {
            switch status {
            case .planned:
                return next == DefaultRemittanceDigestStatus.scheduled
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == DefaultRemittanceDigestStatus.cancelled
            case .completed:
                return next == DefaultRemittanceDigestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultRemittanceDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default remittance digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedLoad() -> Double {
            return (Double(limit) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> DefaultRemittanceDigest {
            return DefaultRemittanceDigest(
                code: code,
                name: name,
                notes: notes,
                active: active,
                limit: limit,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default remittance digest in status planned.
    static func newDefaultRemittanceDigest(_ code: String, name: String) -> DefaultRemittanceDigest {
        return DefaultRemittanceDigest(
            code: code,
            name: name,
            notes: "",
            active: false,
            limit: 0,
            quantity: 0,
            status: DefaultRemittanceDigestStatus.planned
        )
    }
}
