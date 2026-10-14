import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist tier must pass. Check returns its problems, or none.
    protocol WorklistTierRule {
        func check(_ item: WorklistTier) -> [String]
    }

    final class WorklistTierDescriptionLengthRule: WorklistTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistTier) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistTierNameLengthRule: WorklistTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistTier) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistTierRequiredUnitRule: WorklistTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistTier) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistTierCodeLengthRule: WorklistTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistTierCodePrefixRule: WorklistTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WorklistTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a worklist tier.
    final class WorklistTierValidator {
        var rules: [any WorklistTierRule]

        init(rules: [any WorklistTierRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WorklistTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistTier]) -> [String: [String]] {
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

    static func defaultWorklistTierValidator() -> WorklistTierValidator {
        return WorklistTierValidator(
            rules: [
                WorklistTierDescriptionLengthRule(maxLength: 64),
                WorklistTierNameLengthRule(maxLength: 1000),
                WorklistTierRequiredUnitRule(message: "worklist tier needs a value"),
                WorklistTierCodeLengthRule(maxLength: 3600),
                WorklistTierCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
