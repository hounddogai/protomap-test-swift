import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential claim is in its life cycle.
    enum CredentialClaimStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a credential claim and its current status.
    final class CredentialClaim {
        var code: String
        var title: String
        var visitMinutes: Int
        var score: Double
        var approved: Bool
        var discount: Double
        var refills: Int
        var patientRef: String
        var graceDays: Int
        var status: CredentialClaimStatus

        init(code: String, title: String, visitMinutes: Int, score: Double, approved: Bool, discount: Double, refills: Int, patientRef: String, graceDays: Int, status: CredentialClaimStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.score = score
            self.approved = approved
            self.discount = discount
            self.refills = refills
            self.patientRef = patientRef
            self.graceDays = graceDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CredentialClaimStatus) -> Bool {
            switch status {
            case .new:
                return next == CredentialClaimStatus.queued
            case .queued:
                return next == CredentialClaimStatus.done
            case .running:
                return next == CredentialClaimStatus.done
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: CredentialClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("credential claim") \(code)"
        }

        func projectedLoad() -> Double {
            return ((Double(graceDays) - discount) * 100).rounded() / 100
        }

        func copyValue() -> CredentialClaim {
            return CredentialClaim(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                score: score,
                approved: approved,
                discount: discount,
                refills: refills,
                patientRef: patientRef,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a credential claim in status new.
    static func newCredentialClaim(_ code: String, title: String) -> CredentialClaim {
        return CredentialClaim(
            code: code,
            title: title,
            visitMinutes: 0,
            score: 0.0,
            approved: false,
            discount: 0.0,
            refills: 0,
            patientRef: "",
            graceDays: 0,
            status: CredentialClaimStatus.new
        )
    }
}
