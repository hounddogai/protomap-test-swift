import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary skill mix cycle is in its life cycle.
    enum PrimarySkillMixCycleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One primary skill mix cycle, with what the planners need to act on it.
    final class PrimarySkillMixCycle {
        var code: String
        var name: String
        var title: String
        var attempts: Int
        var diagnosisCode: String
        var rate: Double
        var ceiling: Double
        var locale: String
        var expiresAt: Int
        var status: PrimarySkillMixCycleStatus

        init(code: String, name: String, title: String, attempts: Int, diagnosisCode: String, rate: Double, ceiling: Double, locale: String, expiresAt: Int, status: PrimarySkillMixCycleStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.attempts = attempts
            self.diagnosisCode = diagnosisCode
            self.rate = rate
            self.ceiling = ceiling
            self.locale = locale
            self.expiresAt = expiresAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimarySkillMixCycleStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == PrimarySkillMixCycleStatus.suspended || next == PrimarySkillMixCycleStatus.closed
            case .suspended:
                return next == PrimarySkillMixCycleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimarySkillMixCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary skill mix cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("primary skill mix cycle") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(expiresAt) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> PrimarySkillMixCycle {
            return PrimarySkillMixCycle(
                code: code,
                name: name,
                title: title,
                attempts: attempts,
                diagnosisCode: diagnosisCode,
                rate: rate,
                ceiling: ceiling,
                locale: locale,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a primary skill mix cycle in status draft.
    static func newPrimarySkillMixCycle(_ code: String, name: String) -> PrimarySkillMixCycle {
        return PrimarySkillMixCycle(
            code: code,
            name: name,
            title: "",
            attempts: 0,
            diagnosisCode: "",
            rate: 0.0,
            ceiling: 0.0,
            locale: "",
            expiresAt: 0,
            status: PrimarySkillMixCycleStatus.draft
        )
    }
}
