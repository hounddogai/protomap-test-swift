import AcmePlatform
import Foundation

extension Staffing {
    /// Where a seasonal skill mix plan is in its life cycle.
    enum SeasonalSkillMixPlanStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One seasonal skill mix plan, with what the planners need to act on it.
    final class SeasonalSkillMixPlan {
        var code: String
        var label: String
        var version: Int
        var contactEmail: String
        var minimum: Double
        var score: Double
        var durationMinutes: Int
        var sequence: Int
        var startsAt: Int
        var dosageMg: Double
        var discount: Double
        var status: SeasonalSkillMixPlanStatus

        init(code: String, label: String, version: Int, contactEmail: String, minimum: Double, score: Double, durationMinutes: Int, sequence: Int, startsAt: Int, dosageMg: Double, discount: Double, status: SeasonalSkillMixPlanStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.contactEmail = contactEmail
            self.minimum = minimum
            self.score = score
            self.durationMinutes = durationMinutes
            self.sequence = sequence
            self.startsAt = startsAt
            self.dosageMg = dosageMg
            self.discount = discount
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

        func canMoveTo(_ next: SeasonalSkillMixPlanStatus) -> Bool {
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

        func moveTo(_ next: SeasonalSkillMixPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal skill mix plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\("seasonal skill mix plan") \(code)"
        }

        func netTotal() -> Double {
            return ((Double(sequence) - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalSkillMixPlan {
            return SeasonalSkillMixPlan(
                code: code,
                label: label,
                version: version,
                contactEmail: contactEmail,
                minimum: minimum,
                score: score,
                durationMinutes: durationMinutes,
                sequence: sequence,
                startsAt: startsAt,
                dosageMg: dosageMg,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal skill mix plan in status requested.
    static func newSeasonalSkillMixPlan(_ code: String, label: String) -> SeasonalSkillMixPlan {
        return SeasonalSkillMixPlan(
            code: code,
            label: label,
            version: 0,
            contactEmail: "",
            minimum: 0.0,
            score: 0.0,
            durationMinutes: 0,
            sequence: 0,
            startsAt: 0,
            dosageMg: 0.0,
            discount: 0.0,
            status: SeasonalSkillMixPlanStatus.requested
        )
    }
}
