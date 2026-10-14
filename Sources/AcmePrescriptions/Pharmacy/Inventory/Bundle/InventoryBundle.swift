import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory bundle is in its life cycle.
    enum InventoryBundleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A inventory bundle. Its code is unique within a tenant.
    final class InventoryBundle {
        var code: String
        var title: String
        var maximum: Double
        var externalRef: String
        var clinicianID: String
        var payer: String
        var version: Int
        var revision: Int
        var allergy: String
        var locale: String
        var status: InventoryBundleStatus

        init(code: String, title: String, maximum: Double, externalRef: String, clinicianID: String, payer: String, version: Int, revision: Int, allergy: String, locale: String, status: InventoryBundleStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.externalRef = externalRef
            self.clinicianID = clinicianID
            self.payer = payer
            self.version = version
            self.revision = revision
            self.allergy = allergy
            self.locale = locale
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

        func canMoveTo(_ next: InventoryBundleStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
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

        func moveTo(_ next: InventoryBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedVolume() -> Double {
            return ((Double(revision) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> InventoryBundle {
            return InventoryBundle(
                code: code,
                title: title,
                maximum: maximum,
                externalRef: externalRef,
                clinicianID: clinicianID,
                payer: payer,
                version: version,
                revision: revision,
                allergy: allergy,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a inventory bundle in status requested.
    static func newInventoryBundle(_ code: String, title: String) -> InventoryBundle {
        return InventoryBundle(
            code: code,
            title: title,
            maximum: 0.0,
            externalRef: "",
            clinicianID: "",
            payer: "",
            version: 0,
            revision: 0,
            allergy: "",
            locale: "",
            status: InventoryBundleStatus.requested
        )
    }
}
