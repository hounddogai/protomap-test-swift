import AcmePlatform
import Foundation

extension Imaging {
    /// Where a default care protocol slot is in its life cycle.
    enum DefaultCareProtocolSlotStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A default care protocol slot. Its code is unique within a tenant.
    final class DefaultCareProtocolSlot {
        var code: String
        var name: String
        var archived: Bool
        var discount: Double
        var currency: String
        var refills: Int
        var contactEmail: String
        var createdAt: Int
        var endsAt: Int
        var status: DefaultCareProtocolSlotStatus

        init(code: String, name: String, archived: Bool, discount: Double, currency: String, refills: Int, contactEmail: String, createdAt: Int, endsAt: Int, status: DefaultCareProtocolSlotStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.discount = discount
            self.currency = currency
            self.refills = refills
            self.contactEmail = contactEmail
            self.createdAt = createdAt
            self.endsAt = endsAt
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

        func canMoveTo(_ next: DefaultCareProtocolSlotStatus) -> Bool {
            switch status {
            case .requested:
                return next == DefaultCareProtocolSlotStatus.granted
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

        func moveTo(_ next: DefaultCareProtocolSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default care protocol slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("default care protocol slot") \(code)"
        }

        func effectiveExposure() -> Double {
            return (Double(refills) * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> DefaultCareProtocolSlot {
            return DefaultCareProtocolSlot(
                code: code,
                name: name,
                archived: archived,
                discount: discount,
                currency: currency,
                refills: refills,
                contactEmail: contactEmail,
                createdAt: createdAt,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default care protocol slot in status requested.
    static func newDefaultCareProtocolSlot(_ code: String, name: String) -> DefaultCareProtocolSlot {
        return DefaultCareProtocolSlot(
            code: code,
            name: name,
            archived: false,
            discount: 0.0,
            currency: "",
            refills: 0,
            contactEmail: "",
            createdAt: 0,
            endsAt: 0,
            status: DefaultCareProtocolSlotStatus.requested
        )
    }
}
