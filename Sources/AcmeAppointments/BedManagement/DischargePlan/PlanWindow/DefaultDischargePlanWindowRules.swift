import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a default discharge plan window must pass. Check returns its problems, or none.
    protocol DefaultDischargePlanWindowRule {
        func check(_ item: DefaultDischargePlanWindow) -> [String]
    }

    final class DefaultDischargePlanWindowCodePrefixRule: DefaultDischargePlanWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultDischargePlanWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultDischargePlanWindowRequiredNameRule: DefaultDischargePlanWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultDischargePlanWindow) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultDischargePlanWindowAllowedLabelRule: DefaultDischargePlanWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultDischargePlanWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is missing"]
            }
            return []
        }
    }

    final class DefaultDischargePlanWindowAmountRangeRule: DefaultDischargePlanWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultDischargePlanWindow) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a default discharge plan window.
    final class DefaultDischargePlanWindowValidator {
        var rules: [any DefaultDischargePlanWindowRule]

        init(rules: [any DefaultDischargePlanWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultDischargePlanWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultDischargePlanWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultDischargePlanWindow]) -> [String: [String]] {
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

    static func defaultDefaultDischargePlanWindowValidator() -> DefaultDischargePlanWindowValidator {
        return DefaultDischargePlanWindowValidator(
            rules: [
                DefaultDischargePlanWindowCodePrefixRule(prefix: "REF"),
                DefaultDischargePlanWindowRequiredNameRule(message: "default discharge plan window needs this field"),
                DefaultDischargePlanWindowAllowedLabelRule(allowed: ["seasonal"]),
                DefaultDischargePlanWindowAmountRangeRule(min: 2.0, max: 3358.2),
            ]
        )
    }
}
