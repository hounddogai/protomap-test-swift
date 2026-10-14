import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a adaptive alert summary is in its life cycle.
    enum AdaptiveAlertSummaryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One adaptive alert summary, with what the planners need to act on it.
    final class AdaptiveAlertSummary {
        var code: String
        var title: String
        var attributes: [String: String]
        var procedureCode: String
        var locale: String
        var amount: Double
        var status: AdaptiveAlertSummaryStatus

        init(code: String, title: String, attributes: [String: String], procedureCode: String, locale: String, amount: Double, status: AdaptiveAlertSummaryStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.procedureCode = procedureCode
            self.locale = locale
            self.amount = amount
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

        func canMoveTo(_ next: AdaptiveAlertSummaryStatus) -> Bool {
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
                case .active:
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

        func moveTo(_ next: AdaptiveAlertSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive alert summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
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

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> AdaptiveAlertSummary {
            return AdaptiveAlertSummary(
                code: code,
                title: title,
                attributes: attributes,
                procedureCode: procedureCode,
                locale: locale,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a adaptive alert summary in status draft.
    static func newAdaptiveAlertSummary(_ code: String, title: String) -> AdaptiveAlertSummary {
        return AdaptiveAlertSummary(
            code: code,
            title: title,
            attributes: [:],
            procedureCode: "",
            locale: "",
            amount: 0.0,
            status: AdaptiveAlertSummaryStatus.draft
        )
    }
}
