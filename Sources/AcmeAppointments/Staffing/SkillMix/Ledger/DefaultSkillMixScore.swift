import AcmePlatform
import Foundation

extension Staffing {
    /// Where a default skill mix score is in its life cycle.
    enum DefaultSkillMixScoreStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One default skill mix score, with what the planners need to act on it.
    final class DefaultSkillMixScore {
        var code: String
        var title: String
        var copay: Double
        var diagnosisCode: String
        var encounterID: String
        var discount: Double
        var attempts: Int
        var status: DefaultSkillMixScoreStatus

        init(code: String, title: String, copay: Double, diagnosisCode: String, encounterID: String, discount: Double, attempts: Int, status: DefaultSkillMixScoreStatus) {
            self.code = code
            self.title = title
            self.copay = copay
            self.diagnosisCode = diagnosisCode
            self.encounterID = encounterID
            self.discount = discount
            self.attempts = attempts
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

        func canMoveTo(_ next: DefaultSkillMixScoreStatus) -> Bool {
            switch status {
            case .new:
                return next == DefaultSkillMixScoreStatus.queued
            case .queued:
                return next == DefaultSkillMixScoreStatus.done
            case .running:
                return next == DefaultSkillMixScoreStatus.failed
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

        func moveTo(_ next: DefaultSkillMixScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default skill mix score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("default skill mix score") \(code)"
        }

        func projectedTotal() -> Double {
            return (copay * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> DefaultSkillMixScore {
            return DefaultSkillMixScore(
                code: code,
                title: title,
                copay: copay,
                diagnosisCode: diagnosisCode,
                encounterID: encounterID,
                discount: discount,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default skill mix score in status new.
    static func newDefaultSkillMixScore(_ code: String, title: String) -> DefaultSkillMixScore {
        return DefaultSkillMixScore(
            code: code,
            title: title,
            copay: 0.0,
            diagnosisCode: "",
            encounterID: "",
            discount: 0.0,
            attempts: 0,
            status: DefaultSkillMixScoreStatus.new
        )
    }
}
