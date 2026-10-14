import AcmePlatform
import Foundation

extension Staffing {
    /// Where a regional credential tier is in its life cycle.
    enum RegionalCredentialTierStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a regional credential tier and its current status.
    final class RegionalCredentialTier {
        var code: String
        var name: String
        var locale: String
        var channel: String
        var source: String
        var checksum: String
        var quantity: Int
        var status: RegionalCredentialTierStatus

        init(code: String, name: String, locale: String, channel: String, source: String, checksum: String, quantity: Int, status: RegionalCredentialTierStatus) {
            self.code = code
            self.name = name
            self.locale = locale
            self.channel = channel
            self.source = source
            self.checksum = checksum
            self.quantity = quantity
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

        func canMoveTo(_ next: RegionalCredentialTierStatus) -> Bool {
            switch status {
            case .requested:
                return next == RegionalCredentialTierStatus.revoked || next == RegionalCredentialTierStatus.expired
            case .granted:
                return next == RegionalCredentialTierStatus.revoked
            case .revoked:
                return next == RegionalCredentialTierStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalCredentialTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional credential tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("regional credential tier") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> RegionalCredentialTier {
            return RegionalCredentialTier(
                code: code,
                name: name,
                locale: locale,
                channel: channel,
                source: source,
                checksum: checksum,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a regional credential tier in status requested.
    static func newRegionalCredentialTier(_ code: String, name: String) -> RegionalCredentialTier {
        return RegionalCredentialTier(
            code: code,
            name: name,
            locale: "",
            channel: "",
            source: "",
            checksum: "",
            quantity: 0,
            status: RegionalCredentialTierStatus.requested
        )
    }
}
