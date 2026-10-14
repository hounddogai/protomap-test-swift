import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a adaptive isolation baseline is in its life cycle.
    enum AdaptiveIsolationBaselineStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A adaptive isolation baseline. Its code is unique within a tenant.
    final class AdaptiveIsolationBaseline {
        var code: String
        var label: String
        var score: Double
        var ward: String
        var margin: Double
        var priority: Int
        var diagnosisCode: String
        var locale: String
        var ceiling: Double
        var status: AdaptiveIsolationBaselineStatus

        init(code: String, label: String, score: Double, ward: String, margin: Double, priority: Int, diagnosisCode: String, locale: String, ceiling: Double, status: AdaptiveIsolationBaselineStatus) {
            self.code = code
            self.label = label
            self.score = score
            self.ward = ward
            self.margin = margin
            self.priority = priority
            self.diagnosisCode = diagnosisCode
            self.locale = locale
            self.ceiling = ceiling
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

        func canMoveTo(_ next: AdaptiveIsolationBaselineStatus) -> Bool {
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
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == AdaptiveIsolationBaselineStatus.archived
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

        func moveTo(_ next: AdaptiveIsolationBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive isolation baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("adaptive isolation baseline") \(code)"
        }

        func netValue() -> Double {
            return ((score - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveIsolationBaseline {
            return AdaptiveIsolationBaseline(
                code: code,
                label: label,
                score: score,
                ward: ward,
                margin: margin,
                priority: priority,
                diagnosisCode: diagnosisCode,
                locale: locale,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a adaptive isolation baseline in status open.
    static func newAdaptiveIsolationBaseline(_ code: String, label: String) -> AdaptiveIsolationBaseline {
        return AdaptiveIsolationBaseline(
            code: code,
            label: label,
            score: 0.0,
            ward: "",
            margin: 0.0,
            priority: 0,
            diagnosisCode: "",
            locale: "",
            ceiling: 0.0,
            status: AdaptiveIsolationBaselineStatus.`open`
        )
    }
}
