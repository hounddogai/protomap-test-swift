import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a lenient inventory manifest is in its life cycle.
    enum LenientInventoryManifestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A lenient inventory manifest. Its code is unique within a tenant.
    final class LenientInventoryManifest {
        var code: String
        var title: String
        var acuity: Int
        var ownerID: String
        var refills: Int
        var endsAt: Int
        var status: LenientInventoryManifestStatus

        init(code: String, title: String, acuity: Int, ownerID: String, refills: Int, endsAt: Int, status: LenientInventoryManifestStatus) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.ownerID = ownerID
            self.refills = refills
            self.endsAt = endsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientInventoryManifestStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == LenientInventoryManifestStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientInventoryManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient inventory manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedValue() -> Double {
            return ((Double(endsAt) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> LenientInventoryManifest {
            return LenientInventoryManifest(
                code: code,
                title: title,
                acuity: acuity,
                ownerID: ownerID,
                refills: refills,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient inventory manifest in status created.
    static func newLenientInventoryManifest(_ code: String, title: String) -> LenientInventoryManifest {
        return LenientInventoryManifest(
            code: code,
            title: title,
            acuity: 0,
            ownerID: "",
            refills: 0,
            endsAt: 0,
            status: LenientInventoryManifestStatus.created
        )
    }
}
