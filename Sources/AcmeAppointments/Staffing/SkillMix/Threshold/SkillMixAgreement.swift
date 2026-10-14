import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix agreement is in its life cycle.
    enum SkillMixAgreementStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A skill mix agreement as the skill mix team keeps it.
    final class SkillMixAgreement {
        var code: String
        var title: String
        var active: Bool
        var version: Int
        var graceDays: Int
        var attributes: [String: String]
        var cost: Double
        var status: SkillMixAgreementStatus

        init(code: String, title: String, active: Bool, version: Int, graceDays: Int, attributes: [String: String], cost: Double, status: SkillMixAgreementStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.version = version
            self.graceDays = graceDays
            self.attributes = attributes
            self.cost = cost
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

        func canMoveTo(_ next: SkillMixAgreementStatus) -> Bool {
            switch status {
            case .draft:
                return next == SkillMixAgreementStatus.closed
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: SkillMixAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("skill mix agreement") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveLoad() -> Double {
            return ((Double(graceDays) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> SkillMixAgreement {
            return SkillMixAgreement(
                code: code,
                title: title,
                active: active,
                version: version,
                graceDays: graceDays,
                attributes: attributes,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a skill mix agreement in status draft.
    static func newSkillMixAgreement(_ code: String, title: String) -> SkillMixAgreement {
        return SkillMixAgreement(
            code: code,
            title: title,
            active: false,
            version: 0,
            graceDays: 0,
            attributes: [:],
            cost: 0.0,
            status: SkillMixAgreementStatus.draft
        )
    }
}
