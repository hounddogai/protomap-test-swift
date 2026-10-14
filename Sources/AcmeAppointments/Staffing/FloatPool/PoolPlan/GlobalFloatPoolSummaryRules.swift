import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a global float pool summary must pass. Check returns its problems, or none.
    protocol GlobalFloatPoolSummaryRule {
        func check(_ item: GlobalFloatPoolSummary) -> [String]
    }

    final class GlobalFloatPoolSummaryRequiredTitleRule: GlobalFloatPoolSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalFloatPoolSummary) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalFloatPoolSummaryRequiredCodeRule: GlobalFloatPoolSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalFloatPoolSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalFloatPoolSummaryTitleLengthRule: GlobalFloatPoolSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalFloatPoolSummary) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalFloatPoolSummaryCodePrefixRule: GlobalFloatPoolSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalFloatPoolSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalFloatPoolSummaryWindowDaysRangeRule: GlobalFloatPoolSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalFloatPoolSummary) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a global float pool summary.
    final class GlobalFloatPoolSummaryValidator {
        var rules: [any GlobalFloatPoolSummaryRule]

        init(rules: [any GlobalFloatPoolSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalFloatPoolSummary) -> [String] {
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

        func requireValid(_ item: GlobalFloatPoolSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalFloatPoolSummary]) -> [String: [String]] {
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

    static func defaultGlobalFloatPoolSummaryValidator() -> GlobalFloatPoolSummaryValidator {
        return GlobalFloatPoolSummaryValidator(
            rules: [
                GlobalFloatPoolSummaryRequiredTitleRule(message: "global float pool summary needs this field"),
                GlobalFloatPoolSummaryRequiredCodeRule(message: "global float pool summary needs a value"),
                GlobalFloatPoolSummaryTitleLengthRule(maxLength: 86400),
                GlobalFloatPoolSummaryCodePrefixRule(prefix: "REF"),
                GlobalFloatPoolSummaryWindowDaysRangeRule(min: 32, max: 255),
            ]
        )
    }
}
