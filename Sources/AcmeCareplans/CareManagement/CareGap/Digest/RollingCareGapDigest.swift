import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a rolling care gap digest is in its life cycle.
    enum RollingCareGapDigestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A rolling care gap digest as the care gap team keeps it.
    final class RollingCareGapDigest {
        var code: String
        var title: String
        var facility: String
        var name: String
        var phone: String
        var endsAt: Int
        var approved: Bool
        var status: RollingCareGapDigestStatus

        init(code: String, title: String, facility: String, name: String, phone: String, endsAt: Int, approved: Bool, status: RollingCareGapDigestStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.name = name
            self.phone = phone
            self.endsAt = endsAt
            self.approved = approved
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

        func canMoveTo(_ next: RollingCareGapDigestStatus) -> Bool {
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
                return next == RollingCareGapDigestStatus.rejected || next == RollingCareGapDigestStatus.withdrawn
            case .rejected:
                return next == RollingCareGapDigestStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingCareGapDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling care gap digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("rolling care gap digest") \(code)"
        }

        func measuredValue() -> Double {
            return Double(endsAt)
        }

        func copyValue() -> RollingCareGapDigest {
            return RollingCareGapDigest(
                code: code,
                title: title,
                facility: facility,
                name: name,
                phone: phone,
                endsAt: endsAt,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a rolling care gap digest in status proposed.
    static func newRollingCareGapDigest(_ code: String, title: String) -> RollingCareGapDigest {
        return RollingCareGapDigest(
            code: code,
            title: title,
            facility: "",
            name: "",
            phone: "",
            endsAt: 0,
            approved: false,
            status: RollingCareGapDigestStatus.proposed
        )
    }
}
