import AcmePlatform
import Foundation

extension Imaging {
    /// Where a manual modality plan is in its life cycle.
    enum ManualModalityPlanStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One manual modality plan, with what the planners need to act on it.
    final class ManualModalityPlan {
        var code: String
        var title: String
        var maximum: Double
        var margin: Double
        var ceiling: Double
        var locale: String
        var category: String
        var status: ManualModalityPlanStatus

        init(code: String, title: String, maximum: Double, margin: Double, ceiling: Double, locale: String, category: String, status: ManualModalityPlanStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.margin = margin
            self.ceiling = ceiling
            self.locale = locale
            self.category = category
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

        func canMoveTo(_ next: ManualModalityPlanStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
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
                switch next {
                case .archived:
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

        func moveTo(_ next: ManualModalityPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual modality plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("manual modality plan") \(code)"
        }

        func weightedExposure() -> Double {
            return ((margin - maximum) * 100).rounded() / 100
        }

        func copyValue() -> ManualModalityPlan {
            return ManualModalityPlan(
                code: code,
                title: title,
                maximum: maximum,
                margin: margin,
                ceiling: ceiling,
                locale: locale,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a manual modality plan in status open.
    static func newManualModalityPlan(_ code: String, title: String) -> ManualModalityPlan {
        return ManualModalityPlan(
            code: code,
            title: title,
            maximum: 0.0,
            margin: 0.0,
            ceiling: 0.0,
            locale: "",
            category: "",
            status: ManualModalityPlanStatus.`open`
        )
    }
}
