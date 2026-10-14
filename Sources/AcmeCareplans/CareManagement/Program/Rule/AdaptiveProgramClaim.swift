import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a adaptive program claim is in its life cycle.
    enum AdaptiveProgramClaimStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A adaptive program claim as the program team keeps it.
    final class AdaptiveProgramClaim {
        var code: String
        var title: String
        var bed: String
        var durationMinutes: Int
        var approved: Bool
        var archived: Bool
        var budget: Double
        var diagnosisCode: String
        var active: Bool
        var status: AdaptiveProgramClaimStatus

        init(code: String, title: String, bed: String, durationMinutes: Int, approved: Bool, archived: Bool, budget: Double, diagnosisCode: String, active: Bool, status: AdaptiveProgramClaimStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.durationMinutes = durationMinutes
            self.approved = approved
            self.archived = archived
            self.budget = budget
            self.diagnosisCode = diagnosisCode
            self.active = active
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

        func canMoveTo(_ next: AdaptiveProgramClaimStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == AdaptiveProgramClaimStatus.revoked
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

        func moveTo(_ next: AdaptiveProgramClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive program claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedValue() -> Double {
            return ((budget - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveProgramClaim {
            return AdaptiveProgramClaim(
                code: code,
                title: title,
                bed: bed,
                durationMinutes: durationMinutes,
                approved: approved,
                archived: archived,
                budget: budget,
                diagnosisCode: diagnosisCode,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a adaptive program claim in status requested.
    static func newAdaptiveProgramClaim(_ code: String, title: String) -> AdaptiveProgramClaim {
        return AdaptiveProgramClaim(
            code: code,
            title: title,
            bed: "",
            durationMinutes: 0,
            approved: false,
            archived: false,
            budget: 0.0,
            diagnosisCode: "",
            active: false,
            status: AdaptiveProgramClaimStatus.requested
        )
    }
}
