import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure checkpoint is in its life cycle.
    enum DisclosureCheckpointStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A disclosure checkpoint as the disclosure team keeps it.
    final class DisclosureCheckpoint {
        var code: String
        var title: String
        var active: Bool
        var category: String
        var expiresAt: Int
        var name: String
        var ownerID: String
        var weight: Double
        var patientRef: String
        var externalRef: String
        var status: DisclosureCheckpointStatus

        init(code: String, title: String, active: Bool, category: String, expiresAt: Int, name: String, ownerID: String, weight: Double, patientRef: String, externalRef: String, status: DisclosureCheckpointStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.category = category
            self.expiresAt = expiresAt
            self.name = name
            self.ownerID = ownerID
            self.weight = weight
            self.patientRef = patientRef
            self.externalRef = externalRef
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

        func canMoveTo(_ next: DisclosureCheckpointStatus) -> Bool {
            switch status {
            case .requested:
                return next == DisclosureCheckpointStatus.revoked || next == DisclosureCheckpointStatus.expired
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == DisclosureCheckpointStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DisclosureCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("disclosure checkpoint") \(code)"
        }

        func projectedExposure() -> Double {
            return (weight * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureCheckpoint {
            return DisclosureCheckpoint(
                code: code,
                title: title,
                active: active,
                category: category,
                expiresAt: expiresAt,
                name: name,
                ownerID: ownerID,
                weight: weight,
                patientRef: patientRef,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a disclosure checkpoint in status requested.
    static func newDisclosureCheckpoint(_ code: String, title: String) -> DisclosureCheckpoint {
        return DisclosureCheckpoint(
            code: code,
            title: title,
            active: false,
            category: "",
            expiresAt: 0,
            name: "",
            ownerID: "",
            weight: 0.0,
            patientRef: "",
            externalRef: "",
            status: DisclosureCheckpointStatus.requested
        )
    }
}
