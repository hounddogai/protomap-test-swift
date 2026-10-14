import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier digest is in its life cycle.
    enum CourierDigestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A courier digest. Its code is unique within a tenant.
    final class CourierDigest {
        var code: String
        var label: String
        var active: Bool
        var amount: Double
        var category: String
        var minimum: Double
        var archived: Bool
        var status: CourierDigestStatus

        init(code: String, label: String, active: Bool, amount: Double, category: String, minimum: Double, archived: Bool, status: CourierDigestStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.amount = amount
            self.category = category
            self.minimum = minimum
            self.archived = archived
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

        func canMoveTo(_ next: CourierDigestStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CourierDigestStatus.approved || next == CourierDigestStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
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

        func moveTo(_ next: CourierDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveValue() -> Double {
            return ((minimum - amount) * 100).rounded() / 100
        }

        func copyValue() -> CourierDigest {
            return CourierDigest(
                code: code,
                label: label,
                active: active,
                amount: amount,
                category: category,
                minimum: minimum,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a courier digest in status proposed.
    static func newCourierDigest(_ code: String, label: String) -> CourierDigest {
        return CourierDigest(
            code: code,
            label: label,
            active: false,
            amount: 0.0,
            category: "",
            minimum: 0.0,
            archived: false,
            status: CourierDigestStatus.proposed
        )
    }
}
