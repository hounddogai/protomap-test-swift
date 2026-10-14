import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered priority target must pass. Check returns its problems, or none.
    protocol TieredPriorityTargetRule {
        func check(_ item: TieredPriorityTarget) -> [String]
    }

    final class TieredPriorityTargetRequiredNameRule: TieredPriorityTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredPriorityTarget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredPriorityTargetNameLengthRule: TieredPriorityTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredPriorityTarget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredPriorityTargetAmountRangeRule: TieredPriorityTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredPriorityTarget) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredPriorityTargetAllowedCodeRule: TieredPriorityTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredPriorityTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    final class TieredPriorityTargetRequiredDescriptionRule: TieredPriorityTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredPriorityTarget) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered priority target.
    final class TieredPriorityTargetValidator {
        var rules: [any TieredPriorityTargetRule]

        init(rules: [any TieredPriorityTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredPriorityTarget) -> [String] {
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

        func requireValid(_ item: TieredPriorityTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredPriorityTarget]) -> [String: [String]] {
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

    static func defaultTieredPriorityTargetValidator() -> TieredPriorityTargetValidator {
        return TieredPriorityTargetValidator(
            rules: [
                TieredPriorityTargetRequiredNameRule(message: "tiered priority target needs an entry"),
                TieredPriorityTargetNameLengthRule(maxLength: 80),
                TieredPriorityTargetAmountRangeRule(min: 3.8, max: 226.0),
                TieredPriorityTargetAllowedCodeRule(allowed: ["seasonal"]),
                TieredPriorityTargetRequiredDescriptionRule(message: "tiered priority target needs a value"),
            ]
        )
    }
}
