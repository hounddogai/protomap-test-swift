import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge manifest is in its life cycle.
    enum ChargeManifestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A charge manifest. Its code is unique within a tenant.
    final class ChargeManifest {
        var code: String
        var title: String
        var visible: Bool
        var archived: Bool
        var clinicianID: String
        var discount: Double
        var status: ChargeManifestStatus

        init(code: String, title: String, visible: Bool, archived: Bool, clinicianID: String, discount: Double, status: ChargeManifestStatus) {
            self.code = code
            self.title = title
            self.visible = visible
            self.archived = archived
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: ChargeManifestStatus) -> Bool {
            switch status {
            case .requested:
                return next == ChargeManifestStatus.expired
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

        func moveTo(_ next: ChargeManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return discount
        }

        func copyValue() -> ChargeManifest {
            return ChargeManifest(
                code: code,
                title: title,
                visible: visible,
                archived: archived,
                clinicianID: clinicianID,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a charge manifest in status requested.
    static func newChargeManifest(_ code: String, title: String) -> ChargeManifest {
        return ChargeManifest(
            code: code,
            title: title,
            visible: false,
            archived: false,
            clinicianID: "",
            discount: 0.0,
            status: ChargeManifestStatus.requested
        )
    }
}
