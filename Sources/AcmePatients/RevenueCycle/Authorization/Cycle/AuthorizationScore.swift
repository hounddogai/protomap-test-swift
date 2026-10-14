import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization score is in its life cycle.
    enum AuthorizationScoreStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a authorization score and its current status.
    final class AuthorizationScore {
        var code: String
        var title: String
        var threshold: Double
        var batchSize: Int
        var contactEmail: String
        var updatedAt: Int
        var acuity: Int
        var diagnosisCode: String
        var archived: Bool
        var copay: Double
        var graceDays: Int
        var status: AuthorizationScoreStatus

        init(code: String, title: String, threshold: Double, batchSize: Int, contactEmail: String, updatedAt: Int, acuity: Int, diagnosisCode: String, archived: Bool, copay: Double, graceDays: Int, status: AuthorizationScoreStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.batchSize = batchSize
            self.contactEmail = contactEmail
            self.updatedAt = updatedAt
            self.acuity = acuity
            self.diagnosisCode = diagnosisCode
            self.archived = archived
            self.copay = copay
            self.graceDays = graceDays
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

        func canMoveTo(_ next: AuthorizationScoreStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == AuthorizationScoreStatus.revoked || next == AuthorizationScoreStatus.expired
            case .revoked:
                return next == AuthorizationScoreStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AuthorizationScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedLoad() -> Double {
            return ((Double(acuity) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationScore {
            return AuthorizationScore(
                code: code,
                title: title,
                threshold: threshold,
                batchSize: batchSize,
                contactEmail: contactEmail,
                updatedAt: updatedAt,
                acuity: acuity,
                diagnosisCode: diagnosisCode,
                archived: archived,
                copay: copay,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a authorization score in status requested.
    static func newAuthorizationScore(_ code: String, title: String) -> AuthorizationScore {
        return AuthorizationScore(
            code: code,
            title: title,
            threshold: 0.0,
            batchSize: 0,
            contactEmail: "",
            updatedAt: 0,
            acuity: 0,
            diagnosisCode: "",
            archived: false,
            copay: 0.0,
            graceDays: 0,
            status: AuthorizationScoreStatus.requested
        )
    }
}
