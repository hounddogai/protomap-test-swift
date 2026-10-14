import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a regional read summary must pass. Check returns its problems, or none.
    protocol RegionalReadSummaryRule {
        func check(_ item: RegionalReadSummary) -> [String]
    }

    final class RegionalReadSummaryRequiredLabelRule: RegionalReadSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalReadSummary) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalReadSummaryRequiredPhoneRule: RegionalReadSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalReadSummary) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalReadSummaryAllowedSpecialtyRule: RegionalReadSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalReadSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is below minimum"]
            }
            return []
        }
    }

    final class RegionalReadSummaryCodePrefixRule: RegionalReadSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalReadSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalReadSummaryPriorityRangeRule: RegionalReadSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalReadSummary) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional read summary.
    final class RegionalReadSummaryValidator {
        var rules: [any RegionalReadSummaryRule]

        init(rules: [any RegionalReadSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalReadSummary) -> [String] {
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

        func requireValid(_ item: RegionalReadSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalReadSummary]) -> [String: [String]] {
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

    static func defaultRegionalReadSummaryValidator() -> RegionalReadSummaryValidator {
        return RegionalReadSummaryValidator(
            rules: [
                RegionalReadSummaryRequiredLabelRule(message: "regional read summary needs a value"),
                RegionalReadSummaryRequiredPhoneRule(message: "regional read summary needs a value"),
                RegionalReadSummaryAllowedSpecialtyRule(allowed: ["tiered", "legacy"]),
                RegionalReadSummaryCodePrefixRule(prefix: "OPS"),
                RegionalReadSummaryPriorityRangeRule(min: 3600, max: 86400),
            ]
        )
    }
}
