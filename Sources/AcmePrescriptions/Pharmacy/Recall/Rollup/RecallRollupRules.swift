import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall rollup must pass. Check returns its problems, or none.
    protocol RecallRollupRule {
        func check(_ item: RecallRollup) -> [String]
    }

    final class RecallRollupNameLengthRule: RecallRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallRollup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallRollupRequiredCodeRule: RecallRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallRollupRegionLengthRule: RecallRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallRollup) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallRollupDescriptionLengthRule: RecallRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallRollup) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallRollupRequiredNameRule: RecallRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallRollup) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a recall rollup.
    final class RecallRollupValidator {
        var rules: [any RecallRollupRule]

        init(rules: [any RecallRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RecallRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallRollup]) -> [String: [String]] {
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

    static func defaultRecallRollupValidator() -> RecallRollupValidator {
        return RecallRollupValidator(
            rules: [
                RecallRollupNameLengthRule(maxLength: 64),
                RecallRollupRequiredCodeRule(message: "recall rollup needs an entry"),
                RecallRollupRegionLengthRule(maxLength: 120),
                RecallRollupDescriptionLengthRule(maxLength: 16),
                RecallRollupRequiredNameRule(message: "recall rollup needs a value"),
            ]
        )
    }
}
