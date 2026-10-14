import AcmePlatform
import Foundation

extension Staffing {
    /// Where a regional skill mix quota is in its life cycle.
    enum RegionalSkillMixQuotaStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a regional skill mix quota and its current status.
    final class RegionalSkillMixQuota {
        var code: String
        var name: String
        var diagnosisCode: String
        var copay: Double
        var updatedAt: Int
        var country: String
        var discount: Double
        var clinicianID: String
        var status: RegionalSkillMixQuotaStatus

        init(code: String, name: String, diagnosisCode: String, copay: Double, updatedAt: Int, country: String, discount: Double, clinicianID: String, status: RegionalSkillMixQuotaStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.copay = copay
            self.updatedAt = updatedAt
            self.country = country
            self.discount = discount
            self.clinicianID = clinicianID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalSkillMixQuotaStatus) -> Bool {
            switch status {
            case .planned:
                return next == RegionalSkillMixQuotaStatus.scheduled || next == RegionalSkillMixQuotaStatus.inProgress
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: RegionalSkillMixQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional skill mix quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("regional skill mix quota") \(code)"
        }

        func weightedVolume() -> Double {
            return (discount * copay * 100).rounded() / 100
        }

        func copyValue() -> RegionalSkillMixQuota {
            return RegionalSkillMixQuota(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                copay: copay,
                updatedAt: updatedAt,
                country: country,
                discount: discount,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a regional skill mix quota in status planned.
    static func newRegionalSkillMixQuota(_ code: String, name: String) -> RegionalSkillMixQuota {
        return RegionalSkillMixQuota(
            code: code,
            name: name,
            diagnosisCode: "",
            copay: 0.0,
            updatedAt: 0,
            country: "",
            discount: 0.0,
            clinicianID: "",
            status: RegionalSkillMixQuotaStatus.planned
        )
    }
}
