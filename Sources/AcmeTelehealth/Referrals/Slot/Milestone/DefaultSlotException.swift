import AcmePlatform
import Foundation

extension Referrals {
    /// Where a default slot exception is in its life cycle.
    enum DefaultSlotExceptionStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One default slot exception, with what the planners need to act on it.
    final class DefaultSlotException {
        var code: String
        var name: String
        var externalRef: String
        var checksum: String
        var weight: Double
        var phone: String
        var title: String
        var capacity: Int
        var payer: String
        var expiresAt: Int
        var status: DefaultSlotExceptionStatus

        init(code: String, name: String, externalRef: String, checksum: String, weight: Double, phone: String, title: String, capacity: Int, payer: String, expiresAt: Int, status: DefaultSlotExceptionStatus) {
            self.code = code
            self.name = name
            self.externalRef = externalRef
            self.checksum = checksum
            self.weight = weight
            self.phone = phone
            self.title = title
            self.capacity = capacity
            self.payer = payer
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: DefaultSlotExceptionStatus) -> Bool {
            switch status {
            case .requested:
                return next == DefaultSlotExceptionStatus.granted || next == DefaultSlotExceptionStatus.revoked
            case .granted:
                return next == DefaultSlotExceptionStatus.revoked || next == DefaultSlotExceptionStatus.expired
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

        func moveTo(_ next: DefaultSlotExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default slot exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netExposure() -> Double {
            return ((weight - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultSlotException {
            return DefaultSlotException(
                code: code,
                name: name,
                externalRef: externalRef,
                checksum: checksum,
                weight: weight,
                phone: phone,
                title: title,
                capacity: capacity,
                payer: payer,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default slot exception in status requested.
    static func newDefaultSlotException(_ code: String, name: String) -> DefaultSlotException {
        return DefaultSlotException(
            code: code,
            name: name,
            externalRef: "",
            checksum: "",
            weight: 0.0,
            phone: "",
            title: "",
            capacity: 0,
            payer: "",
            expiresAt: 0,
            status: DefaultSlotExceptionStatus.requested
        )
    }
}
