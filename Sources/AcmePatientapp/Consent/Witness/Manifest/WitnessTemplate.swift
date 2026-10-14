import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness template is in its life cycle.
    enum WitnessTemplateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One witness template, with what the planners need to act on it.
    final class WitnessTemplate {
        var code: String
        var title: String
        var locale: String
        var externalRef: String
        var category: String
        var score: Double
        var status: WitnessTemplateStatus

        init(code: String, title: String, locale: String, externalRef: String, category: String, score: Double, status: WitnessTemplateStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.externalRef = externalRef
            self.category = category
            self.score = score
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

        func canMoveTo(_ next: WitnessTemplateStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == WitnessTemplateStatus.cancelled
            case .inProgress:
                switch next {
                case .completed:
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

        func moveTo(_ next: WitnessTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> WitnessTemplate {
            return WitnessTemplate(
                code: code,
                title: title,
                locale: locale,
                externalRef: externalRef,
                category: category,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a witness template in status planned.
    static func newWitnessTemplate(_ code: String, title: String) -> WitnessTemplate {
        return WitnessTemplate(
            code: code,
            title: title,
            locale: "",
            externalRef: "",
            category: "",
            score: 0.0,
            status: WitnessTemplateStatus.planned
        )
    }
}
