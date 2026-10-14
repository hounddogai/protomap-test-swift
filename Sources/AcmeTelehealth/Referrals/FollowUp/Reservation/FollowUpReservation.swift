import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up reservation is in its life cycle.
    enum FollowUpReservationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A follow up reservation. Its code is unique within a tenant.
    final class FollowUpReservation {
        var code: String
        var name: String
        var ward: String
        var discount: Double
        var title: String
        var copay: Double
        var createdAt: Int
        var status: FollowUpReservationStatus

        init(code: String, name: String, ward: String, discount: Double, title: String, copay: Double, createdAt: Int, status: FollowUpReservationStatus) {
            self.code = code
            self.name = name
            self.ward = ward
            self.discount = discount
            self.title = title
            self.copay = copay
            self.createdAt = createdAt
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

        func canMoveTo(_ next: FollowUpReservationStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
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
                switch next {
                case .expired:
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

        func moveTo(_ next: FollowUpReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("follow up reservation") \(code)"
        }

        func weightedLoad() -> Double {
            return (Double(createdAt) * discount * 100).rounded() / 100
        }

        func copyValue() -> FollowUpReservation {
            return FollowUpReservation(
                code: code,
                name: name,
                ward: ward,
                discount: discount,
                title: title,
                copay: copay,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a follow up reservation in status requested.
    static func newFollowUpReservation(_ code: String, name: String) -> FollowUpReservation {
        return FollowUpReservation(
            code: code,
            name: name,
            ward: "",
            discount: 0.0,
            title: "",
            copay: 0.0,
            createdAt: 0,
            status: FollowUpReservationStatus.requested
        )
    }
}
