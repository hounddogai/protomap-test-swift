import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a pending interaction metric must pass. Check returns its problems, or none.
    protocol PendingInteractionMetricRule {
        func check(_ item: PendingInteractionMetric) -> [String]
    }

    final class PendingInteractionMetricAllowedEncounterIDRule: PendingInteractionMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingInteractionMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.encounterID)) {
                return ["encounter id \(item.encounterID) is too long"]
            }
            return []
        }
    }

    final class PendingInteractionMetricLabelLengthRule: PendingInteractionMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingInteractionMetric) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingInteractionMetricRequiredEncounterIDRule: PendingInteractionMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingInteractionMetric) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending interaction metric.
    final class PendingInteractionMetricValidator {
        var rules: [any PendingInteractionMetricRule]

        init(rules: [any PendingInteractionMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingInteractionMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: PendingInteractionMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingInteractionMetric]) -> [String: [String]] {
            var report: [String: [String]] = [:]
            for item in items {
                let problems = self.validate(item)
                if problems.count > 0 {
                    report[item.code] = problems
                }
            }
            return report
        }
    }

    static func defaultPendingInteractionMetricValidator() -> PendingInteractionMetricValidator {
        return PendingInteractionMetricValidator(
            rules: [
                PendingInteractionMetricAllowedEncounterIDRule(allowed: ["batched"]),
                PendingInteractionMetricLabelLengthRule(maxLength: 64),
                PendingInteractionMetricRequiredEncounterIDRule(message: "pending interaction metric needs a value"),
            ]
        )
    }
}
