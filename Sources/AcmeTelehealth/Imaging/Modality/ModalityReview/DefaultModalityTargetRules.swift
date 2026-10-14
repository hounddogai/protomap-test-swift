import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a default modality target must pass. Check returns its problems, or none.
    protocol DefaultModalityTargetRule {
        func check(_ item: DefaultModalityTarget) -> [String]
    }

    final class DefaultModalityTargetRequiredTitleRule: DefaultModalityTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultModalityTarget) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultModalityTargetCreatedAtRangeRule: DefaultModalityTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultModalityTarget) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultModalityTargetUpdatedAtRangeRule: DefaultModalityTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultModalityTarget) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultModalityTargetCodeLengthRule: DefaultModalityTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultModalityTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultModalityTargetRequiredLabelRule: DefaultModalityTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultModalityTarget) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default modality target.
    final class DefaultModalityTargetValidator {
        var rules: [any DefaultModalityTargetRule]

        init(rules: [any DefaultModalityTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultModalityTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultModalityTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultModalityTarget]) -> [String: [String]] {
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

    static func defaultDefaultModalityTargetValidator() -> DefaultModalityTargetValidator {
        return DefaultModalityTargetValidator(
            rules: [
                DefaultModalityTargetRequiredTitleRule(message: "default modality target needs a value"),
                DefaultModalityTargetCreatedAtRangeRule(min: 16, max: 1000),
                DefaultModalityTargetUpdatedAtRangeRule(min: 1000, max: 3600),
                DefaultModalityTargetCodeLengthRule(maxLength: 3600),
                DefaultModalityTargetRequiredLabelRule(message: "default modality target needs this field"),
            ]
        )
    }
}
