import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a lenient inventory override is in its life cycle.
    enum LenientInventoryOverrideStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A lenient inventory override as the inventory team keeps it.
    final class LenientInventoryOverride {
        var code: String
        var label: String
        var margin: Double
        var region: String
        var updatedAt: Int
        var contactEmail: String
        var name: String
        var graceDays: Int
        var phone: String
        var rate: Double
        var discount: Double
        var status: LenientInventoryOverrideStatus

        init(code: String, label: String, margin: Double, region: String, updatedAt: Int, contactEmail: String, name: String, graceDays: Int, phone: String, rate: Double, discount: Double, status: LenientInventoryOverrideStatus) {
            self.code = code
            self.label = label
            self.margin = margin
            self.region = region
            self.updatedAt = updatedAt
            self.contactEmail = contactEmail
            self.name = name
            self.graceDays = graceDays
            self.phone = phone
            self.rate = rate
            self.discount = discount
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

        func canMoveTo(_ next: LenientInventoryOverrideStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == LenientInventoryOverrideStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientInventoryOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient inventory override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedLoad() -> Double {
            return (margin * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> LenientInventoryOverride {
            return LenientInventoryOverride(
                code: code,
                label: label,
                margin: margin,
                region: region,
                updatedAt: updatedAt,
                contactEmail: contactEmail,
                name: name,
                graceDays: graceDays,
                phone: phone,
                rate: rate,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a lenient inventory override in status requested.
    static func newLenientInventoryOverride(_ code: String, label: String) -> LenientInventoryOverride {
        return LenientInventoryOverride(
            code: code,
            label: label,
            margin: 0.0,
            region: "",
            updatedAt: 0,
            contactEmail: "",
            name: "",
            graceDays: 0,
            phone: "",
            rate: 0.0,
            discount: 0.0,
            status: LenientInventoryOverrideStatus.requested
        )
    }
}
