import AcmePlatform
import Foundation

extension Labs {
    /// Where a default courier claim is in its life cycle.
    enum DefaultCourierClaimStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A default courier claim. Its code is unique within a tenant.
    final class DefaultCourierClaim {
        var code: String
        var name: String
        var startsAt: Int
        var facility: String
        var quantity: Int
        var status: DefaultCourierClaimStatus

        init(code: String, name: String, startsAt: Int, facility: String, quantity: Int, status: DefaultCourierClaimStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.facility = facility
            self.quantity = quantity
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

        func canMoveTo(_ next: DefaultCourierClaimStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DefaultCourierClaimStatus.approved || next == DefaultCourierClaimStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == DefaultCourierClaimStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultCourierClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default courier claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("default courier claim") \(code)"
        }

        func netLoad() -> Double {
            return ((Double(startsAt) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultCourierClaim {
            return DefaultCourierClaim(
                code: code,
                name: name,
                startsAt: startsAt,
                facility: facility,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a default courier claim in status proposed.
    static func newDefaultCourierClaim(_ code: String, name: String) -> DefaultCourierClaim {
        return DefaultCourierClaim(
            code: code,
            name: name,
            startsAt: 0,
            facility: "",
            quantity: 0,
            status: DefaultCourierClaimStatus.proposed
        )
    }
}
