import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist mapping must pass. Check returns its problems, or none.
    protocol WorklistMappingRule {
        func check(_ item: WorklistMapping) -> [String]
    }

    final class WorklistMappingCodePrefixRule: WorklistMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WorklistMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WorklistMappingNameLengthRule: WorklistMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistMapping) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistMappingRefillsRangeRule: WorklistMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistMapping) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a worklist mapping.
    final class WorklistMappingValidator {
        var rules: [any WorklistMappingRule]

        init(rules: [any WorklistMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistMapping) -> [String] {
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

        func requireValid(_ item: WorklistMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistMapping]) -> [String: [String]] {
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

    static func defaultWorklistMappingValidator() -> WorklistMappingValidator {
        return WorklistMappingValidator(
            rules: [
                WorklistMappingCodePrefixRule(prefix: "ACM"),
                WorklistMappingNameLengthRule(maxLength: 86400),
                WorklistMappingRefillsRangeRule(min: 80, max: 120),
            ]
        )
    }
}
