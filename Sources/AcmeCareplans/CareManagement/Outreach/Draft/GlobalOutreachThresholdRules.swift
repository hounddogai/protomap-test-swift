import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a global outreach threshold must pass. Check returns its problems, or none.
    protocol GlobalOutreachThresholdRule {
        func check(_ item: GlobalOutreachThreshold) -> [String]
    }

    final class GlobalOutreachThresholdRequiredNameRule: GlobalOutreachThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalOutreachThreshold) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalOutreachThresholdNameLengthRule: GlobalOutreachThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalOutreachThreshold) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalOutreachThresholdCategoryLengthRule: GlobalOutreachThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalOutreachThreshold) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalOutreachThresholdCodePrefixRule: GlobalOutreachThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalOutreachThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalOutreachThresholdPriorityRangeRule: GlobalOutreachThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalOutreachThreshold) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a global outreach threshold.
    final class GlobalOutreachThresholdValidator {
        var rules: [any GlobalOutreachThresholdRule]

        init(rules: [any GlobalOutreachThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalOutreachThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalOutreachThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalOutreachThreshold]) -> [String: [String]] {
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

    static func defaultGlobalOutreachThresholdValidator() -> GlobalOutreachThresholdValidator {
        return GlobalOutreachThresholdValidator(
            rules: [
                GlobalOutreachThresholdRequiredNameRule(message: "global outreach threshold needs an entry"),
                GlobalOutreachThresholdNameLengthRule(maxLength: 64),
                GlobalOutreachThresholdCategoryLengthRule(maxLength: 32),
                GlobalOutreachThresholdCodePrefixRule(prefix: "ACM"),
                GlobalOutreachThresholdPriorityRangeRule(min: 120, max: 255),
            ]
        )
    }
}
