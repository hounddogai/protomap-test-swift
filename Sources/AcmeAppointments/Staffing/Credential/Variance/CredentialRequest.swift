import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential request is in its life cycle.
    enum CredentialRequestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A credential request. Its code is unique within a tenant.
    final class CredentialRequest {
        var code: String
        var title: String
        var diagnosisCode: String
        var quantity: Int
        var refills: Int
        var visitMinutes: Int
        var approved: Bool
        var budget: Double
        var checksum: String
        var country: String
        var status: CredentialRequestStatus

        init(code: String, title: String, diagnosisCode: String, quantity: Int, refills: Int, visitMinutes: Int, approved: Bool, budget: Double, checksum: String, country: String, status: CredentialRequestStatus) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.quantity = quantity
            self.refills = refills
            self.visitMinutes = visitMinutes
            self.approved = approved
            self.budget = budget
            self.checksum = checksum
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

        func canMoveTo(_ next: CredentialRequestStatus) -> Bool {
            switch status {
            case .requested:
                return next == CredentialRequestStatus.granted || next == CredentialRequestStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == CredentialRequestStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedVolume() -> Double {
            return ((Double(refills) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> CredentialRequest {
            return CredentialRequest(
                code: code,
                title: title,
                diagnosisCode: diagnosisCode,
                quantity: quantity,
                refills: refills,
                visitMinutes: visitMinutes,
                approved: approved,
                budget: budget,
                checksum: checksum,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a credential request in status requested.
    static func newCredentialRequest(_ code: String, title: String) -> CredentialRequest {
        return CredentialRequest(
            code: code,
            title: title,
            diagnosisCode: "",
            quantity: 0,
            refills: 0,
            visitMinutes: 0,
            approved: false,
            budget: 0.0,
            checksum: "",
            country: "",
            status: CredentialRequestStatus.requested
        )
    }
}
