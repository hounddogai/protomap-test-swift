import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure rule is in its life cycle.
    enum DisclosureRuleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A disclosure rule. Its code is unique within a tenant.
    final class DisclosureRule {
        var code: String
        var label: String
        var unit: String
        var budget: Double
        var graceDays: Int
        var windowDays: Int
        var patientRef: String
        var batchSize: Int
        var attributes: [String: String]
        var timezone: String
        var status: DisclosureRuleStatus

        init(code: String, label: String, unit: String, budget: Double, graceDays: Int, windowDays: Int, patientRef: String, batchSize: Int, attributes: [String: String], timezone: String, status: DisclosureRuleStatus) {
            self.code = code
            self.label = label
            self.unit = unit
            self.budget = budget
            self.graceDays = graceDays
            self.windowDays = windowDays
            self.patientRef = patientRef
            self.batchSize = batchSize
            self.attributes = attributes
            self.timezone = timezone
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

        func canMoveTo(_ next: DisclosureRuleStatus) -> Bool {
            switch status {
            case .planned:
                return next == DisclosureRuleStatus.completed
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == DisclosureRuleStatus.completed
            case .completed:
                return next == DisclosureRuleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DisclosureRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
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

        func netVolume() -> Double {
            return ((Double(batchSize) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureRule {
            return DisclosureRule(
                code: code,
                label: label,
                unit: unit,
                budget: budget,
                graceDays: graceDays,
                windowDays: windowDays,
                patientRef: patientRef,
                batchSize: batchSize,
                attributes: attributes,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a disclosure rule in status planned.
    static func newDisclosureRule(_ code: String, label: String) -> DisclosureRule {
        return DisclosureRule(
            code: code,
            label: label,
            unit: "",
            budget: 0.0,
            graceDays: 0,
            windowDays: 0,
            patientRef: "",
            batchSize: 0,
            attributes: [:],
            timezone: "",
            status: DisclosureRuleStatus.planned
        )
    }
}
