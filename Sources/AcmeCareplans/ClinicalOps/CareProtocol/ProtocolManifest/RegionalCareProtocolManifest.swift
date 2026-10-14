import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a regional care protocol manifest is in its life cycle.
    enum RegionalCareProtocolManifestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One regional care protocol manifest, with what the planners need to act on it.
    final class RegionalCareProtocolManifest {
        var code: String
        var label: String
        var retries: Int
        var clinicianID: String
        var allergy: String
        var approved: Bool
        var windowDays: Int
        var active: Bool
        var title: String
        var ward: String
        var status: RegionalCareProtocolManifestStatus

        init(code: String, label: String, retries: Int, clinicianID: String, allergy: String, approved: Bool, windowDays: Int, active: Bool, title: String, ward: String, status: RegionalCareProtocolManifestStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.clinicianID = clinicianID
            self.allergy = allergy
            self.approved = approved
            self.windowDays = windowDays
            self.active = active
            self.title = title
            self.ward = ward
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

        func canMoveTo(_ next: RegionalCareProtocolManifestStatus) -> Bool {
            switch status {
            case .requested:
                return next == RegionalCareProtocolManifestStatus.revoked
            case .granted:
                return next == RegionalCareProtocolManifestStatus.revoked || next == RegionalCareProtocolManifestStatus.expired
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

        func moveTo(_ next: RegionalCareProtocolManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional care protocol manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveExposure() -> Double {
            return ((Double(windowDays) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalCareProtocolManifest {
            return RegionalCareProtocolManifest(
                code: code,
                label: label,
                retries: retries,
                clinicianID: clinicianID,
                allergy: allergy,
                approved: approved,
                windowDays: windowDays,
                active: active,
                title: title,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a regional care protocol manifest in status requested.
    static func newRegionalCareProtocolManifest(_ code: String, label: String) -> RegionalCareProtocolManifest {
        return RegionalCareProtocolManifest(
            code: code,
            label: label,
            retries: 0,
            clinicianID: "",
            allergy: "",
            approved: false,
            windowDays: 0,
            active: false,
            title: "",
            ward: "",
            status: RegionalCareProtocolManifestStatus.requested
        )
    }
}
