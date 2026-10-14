import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix preference is in its life cycle.
    enum SkillMixPreferenceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a skill mix preference and its current status.
    final class SkillMixPreference {
        var code: String
        var label: String
        var cost: Double
        var discount: Double
        var margin: Double
        var locale: String
        var unit: String
        var active: Bool
        var status: SkillMixPreferenceStatus

        init(code: String, label: String, cost: Double, discount: Double, margin: Double, locale: String, unit: String, active: Bool, status: SkillMixPreferenceStatus) {
            self.code = code
            self.label = label
            self.cost = cost
            self.discount = discount
            self.margin = margin
            self.locale = locale
            self.unit = unit
            self.active = active
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

        func canMoveTo(_ next: SkillMixPreferenceStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
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

        func moveTo(_ next: SkillMixPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("skill mix preference") \(code)"
        }

        func weightedVolume() -> Double {
            return (discount * margin * 100).rounded() / 100
        }

        func copyValue() -> SkillMixPreference {
            return SkillMixPreference(
                code: code,
                label: label,
                cost: cost,
                discount: discount,
                margin: margin,
                locale: locale,
                unit: unit,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a skill mix preference in status draft.
    static func newSkillMixPreference(_ code: String, label: String) -> SkillMixPreference {
        return SkillMixPreference(
            code: code,
            label: label,
            cost: 0.0,
            discount: 0.0,
            margin: 0.0,
            locale: "",
            unit: "",
            active: false,
            status: SkillMixPreferenceStatus.draft
        )
    }
}
