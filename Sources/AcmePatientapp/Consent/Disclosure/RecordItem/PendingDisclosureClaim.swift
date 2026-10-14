import AcmePlatform
import Foundation

extension Consent {
    /// Where a pending disclosure claim is in its life cycle.
    enum PendingDisclosureClaimStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A pending disclosure claim. Its code is unique within a tenant.
    final class PendingDisclosureClaim {
        var code: String
        var name: String
        var durationMinutes: Int
        var encounterID: String
        var minimum: Double
        var diagnosisCode: String
        var description: String
        var createdAt: Int
        var procedureCode: String
        var rate: Double
        var country: String
        var status: PendingDisclosureClaimStatus

        init(code: String, name: String, durationMinutes: Int, encounterID: String, minimum: Double, diagnosisCode: String, description: String, createdAt: Int, procedureCode: String, rate: Double, country: String, status: PendingDisclosureClaimStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.encounterID = encounterID
            self.minimum = minimum
            self.diagnosisCode = diagnosisCode
            self.description = description
            self.createdAt = createdAt
            self.procedureCode = procedureCode
            self.rate = rate
            self.country = country
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

        func canMoveTo(_ next: PendingDisclosureClaimStatus) -> Bool {
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
                return next == PendingDisclosureClaimStatus.expired
            case .revoked:
                return next == PendingDisclosureClaimStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingDisclosureClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending disclosure claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedTotal() -> Double {
            return (Double(durationMinutes) * rate * 100).rounded() / 100
        }

        func copyValue() -> PendingDisclosureClaim {
            return PendingDisclosureClaim(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                encounterID: encounterID,
                minimum: minimum,
                diagnosisCode: diagnosisCode,
                description: description,
                createdAt: createdAt,
                procedureCode: procedureCode,
                rate: rate,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a pending disclosure claim in status requested.
    static func newPendingDisclosureClaim(_ code: String, name: String) -> PendingDisclosureClaim {
        return PendingDisclosureClaim(
            code: code,
            name: name,
            durationMinutes: 0,
            encounterID: "",
            minimum: 0.0,
            diagnosisCode: "",
            description: "",
            createdAt: 0,
            procedureCode: "",
            rate: 0.0,
            country: "",
            status: PendingDisclosureClaimStatus.requested
        )
    }
}
