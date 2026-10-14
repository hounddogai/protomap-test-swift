import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure budget is in its life cycle.
    enum DisclosureBudgetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A disclosure budget. Its code is unique within a tenant.
    final class DisclosureBudget {
        var code: String
        var title: String
        var country: String
        var active: Bool
        var acuity: Int
        var description: String
        var patientRef: String
        var diagnosisCode: String
        var score: Double
        var attempts: Int
        var status: DisclosureBudgetStatus

        init(code: String, title: String, country: String, active: Bool, acuity: Int, description: String, patientRef: String, diagnosisCode: String, score: Double, attempts: Int, status: DisclosureBudgetStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.active = active
            self.acuity = acuity
            self.description = description
            self.patientRef = patientRef
            self.diagnosisCode = diagnosisCode
            self.score = score
            self.attempts = attempts
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DisclosureBudgetStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == DisclosureBudgetStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DisclosureBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedValue() -> Double {
            return ((Double(attempts) + score) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureBudget {
            return DisclosureBudget(
                code: code,
                title: title,
                country: country,
                active: active,
                acuity: acuity,
                description: description,
                patientRef: patientRef,
                diagnosisCode: diagnosisCode,
                score: score,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a disclosure budget in status open.
    static func newDisclosureBudget(_ code: String, title: String) -> DisclosureBudget {
        return DisclosureBudget(
            code: code,
            title: title,
            country: "",
            active: false,
            acuity: 0,
            description: "",
            patientRef: "",
            diagnosisCode: "",
            score: 0.0,
            attempts: 0,
            status: DisclosureBudgetStatus.`open`
        )
    }
}
