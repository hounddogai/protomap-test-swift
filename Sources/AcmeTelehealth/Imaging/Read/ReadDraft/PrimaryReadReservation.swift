import AcmePlatform
import Foundation

extension Imaging {
    /// Where a primary read reservation is in its life cycle.
    enum PrimaryReadReservationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A primary read reservation as the read team keeps it.
    final class PrimaryReadReservation {
        var code: String
        var title: String
        var approved: Bool
        var checksum: String
        var phone: String
        var channel: String
        var updatedAt: Int
        var amount: Double
        var procedureCode: String
        var status: PrimaryReadReservationStatus

        init(code: String, title: String, approved: Bool, checksum: String, phone: String, channel: String, updatedAt: Int, amount: Double, procedureCode: String, status: PrimaryReadReservationStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.checksum = checksum
            self.phone = phone
            self.channel = channel
            self.updatedAt = updatedAt
            self.amount = amount
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: PrimaryReadReservationStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == PrimaryReadReservationStatus.revoked || next == PrimaryReadReservationStatus.expired
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

        func moveTo(_ next: PrimaryReadReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary read reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedLoad() -> Double {
            return ((Double(updatedAt) - amount) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryReadReservation {
            return PrimaryReadReservation(
                code: code,
                title: title,
                approved: approved,
                checksum: checksum,
                phone: phone,
                channel: channel,
                updatedAt: updatedAt,
                amount: amount,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a primary read reservation in status requested.
    static func newPrimaryReadReservation(_ code: String, title: String) -> PrimaryReadReservation {
        return PrimaryReadReservation(
            code: code,
            title: title,
            approved: false,
            checksum: "",
            phone: "",
            channel: "",
            updatedAt: 0,
            amount: 0.0,
            procedureCode: "",
            status: PrimaryReadReservationStatus.requested
        )
    }
}
