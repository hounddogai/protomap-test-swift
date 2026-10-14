import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge rollup must pass. Check returns its problems, or none.
    protocol ChargeRollupRule {
        func check(_ item: ChargeRollup) -> [String]
    }

    final class ChargeRollupMaximumRangeRule: ChargeRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeRollup) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ChargeRollupNameLengthRule: ChargeRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeRollup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeRollupRequiredCodeRule: ChargeRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargeRollupApprovedGuardRule: ChargeRollupRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ChargeRollup) -> [String] {
            if item.approved && (item.maximum > limit) {
                return ["maximum \(item.maximum) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a charge rollup.
    final class ChargeRollupValidator {
        var rules: [any ChargeRollupRule]

        init(rules: [any ChargeRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeRollup) -> [String] {
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

        func requireValid(_ item: ChargeRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeRollup]) -> [String: [String]] {
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

    static func defaultChargeRollupValidator() -> ChargeRollupValidator {
        return ChargeRollupValidator(
            rules: [
                ChargeRollupMaximumRangeRule(min: 4.8, max: 4302.2),
                ChargeRollupNameLengthRule(maxLength: 1000),
                ChargeRollupRequiredCodeRule(message: "charge rollup needs an entry"),
                ChargeRollupApprovedGuardRule(limit: 1.3),
            ]
        )
    }
}
