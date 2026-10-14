import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix bundle is in its life cycle.
    enum SkillMixBundleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A skill mix bundle. Its code is unique within a tenant.
    final class SkillMixBundle {
        var code: String
        var title: String
        var approved: Bool
        var copay: Double
        var name: String
        var locale: String
        var status: SkillMixBundleStatus

        init(code: String, title: String, approved: Bool, copay: Double, name: String, locale: String, status: SkillMixBundleStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.copay = copay
            self.name = name
            self.locale = locale
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

        func canMoveTo(_ next: SkillMixBundleStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .suspended:
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
                switch next {
                case .suspended, .closed:
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

        func moveTo(_ next: SkillMixBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> SkillMixBundle {
            return SkillMixBundle(
                code: code,
                title: title,
                approved: approved,
                copay: copay,
                name: name,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a skill mix bundle in status draft.
    static func newSkillMixBundle(_ code: String, title: String) -> SkillMixBundle {
        return SkillMixBundle(
            code: code,
            title: title,
            approved: false,
            copay: 0.0,
            name: "",
            locale: "",
            status: SkillMixBundleStatus.draft
        )
    }
}
