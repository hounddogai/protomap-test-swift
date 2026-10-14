import AcmePlatform
import Foundation

extension Consent {
    /// Where a legacy revocation manifest is in its life cycle.
    enum LegacyRevocationManifestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A legacy revocation manifest. Its code is unique within a tenant.
    final class LegacyRevocationManifest {
        var code: String
        var name: String
        var diagnosisCode: String
        var checksum: String
        var procedureCode: String
        var category: String
        var phone: String
        var retries: Int
        var contactEmail: String
        var weight: Double
        var timezone: String
        var status: LegacyRevocationManifestStatus

        init(code: String, name: String, diagnosisCode: String, checksum: String, procedureCode: String, category: String, phone: String, retries: Int, contactEmail: String, weight: Double, timezone: String, status: LegacyRevocationManifestStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.checksum = checksum
            self.procedureCode = procedureCode
            self.category = category
            self.phone = phone
            self.retries = retries
            self.contactEmail = contactEmail
            self.weight = weight
            self.timezone = timezone
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

        func canMoveTo(_ next: LegacyRevocationManifestStatus) -> Bool {
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

        func moveTo(_ next: LegacyRevocationManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy revocation manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveExposure() -> Double {
            return ((Double(retries) + weight) * 100).rounded() / 100
        }

        func copyValue() -> LegacyRevocationManifest {
            return LegacyRevocationManifest(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                checksum: checksum,
                procedureCode: procedureCode,
                category: category,
                phone: phone,
                retries: retries,
                contactEmail: contactEmail,
                weight: weight,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a legacy revocation manifest in status requested.
    static func newLegacyRevocationManifest(_ code: String, name: String) -> LegacyRevocationManifest {
        return LegacyRevocationManifest(
            code: code,
            name: name,
            diagnosisCode: "",
            checksum: "",
            procedureCode: "",
            category: "",
            phone: "",
            retries: 0,
            contactEmail: "",
            weight: 0.0,
            timezone: "",
            status: LegacyRevocationManifestStatus.requested
        )
    }
}
