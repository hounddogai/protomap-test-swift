import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range rollup must pass. Check returns its problems, or none.
    protocol ReferenceRangeRollupRule {
        func check(_ item: ReferenceRangeRollup) -> [String]
    }

    final class ReferenceRangeRollupCodePrefixRule: ReferenceRangeRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReferenceRangeRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ReferenceRangeRollupUpdatedAtRangeRule: ReferenceRangeRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeRollup) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferenceRangeRollupRequiredUnitRule: ReferenceRangeRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeRollup) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeRollupAllowedTitleRule: ReferenceRangeRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferenceRangeRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a reference range rollup.
    final class ReferenceRangeRollupValidator {
        var rules: [any ReferenceRangeRollupRule]

        init(rules: [any ReferenceRangeRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferenceRangeRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeRollup]) -> [String: [String]] {
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

    static func defaultReferenceRangeRollupValidator() -> ReferenceRangeRollupValidator {
        return ReferenceRangeRollupValidator(
            rules: [
                ReferenceRangeRollupCodePrefixRule(prefix: "REF"),
                ReferenceRangeRollupUpdatedAtRangeRule(min: 64, max: 80),
                ReferenceRangeRollupRequiredUnitRule(message: "reference range rollup needs this field"),
                ReferenceRangeRollupAllowedTitleRule(allowed: []),
            ]
        )
    }
}
