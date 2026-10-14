import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a scheduled alert summary is in its life cycle.
    enum ScheduledAlertSummaryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A scheduled alert summary. Its code is unique within a tenant.
    final class ScheduledAlertSummary {
        var code: String
        var label: String
        var amount: Double
        var locale: String
        var attributes: [String: String]
        var visible: Bool
        var status: ScheduledAlertSummaryStatus

        init(code: String, label: String, amount: Double, locale: String, attributes: [String: String], visible: Bool, status: ScheduledAlertSummaryStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.locale = locale
            self.attributes = attributes
            self.visible = visible
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledAlertSummaryStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ScheduledAlertSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled alert summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
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

        func copyValue() -> ScheduledAlertSummary {
            return ScheduledAlertSummary(
                code: code,
                label: label,
                amount: amount,
                locale: locale,
                attributes: attributes,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a scheduled alert summary in status created.
    static func newScheduledAlertSummary(_ code: String, label: String) -> ScheduledAlertSummary {
        return ScheduledAlertSummary(
            code: code,
            label: label,
            amount: 0.0,
            locale: "",
            attributes: [:],
            visible: false,
            status: ScheduledAlertSummaryStatus.created
        )
    }
}
