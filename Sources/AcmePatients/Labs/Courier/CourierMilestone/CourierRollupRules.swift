import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier rollup must pass. Check returns its problems, or none.
    protocol CourierRollupRule {
        func check(_ item: CourierRollup) -> [String]
    }

    final class CourierRollupRequiredUnitRule: CourierRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierRollup) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierRollupTitleLengthRule: CourierRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierRollup) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CourierRollupUnitLengthRule: CourierRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierRollup) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CourierRollupAllowedCountryRule: CourierRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CourierRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is not allowed"]
            }
            return []
        }
    }

    final class CourierRollupRequiredTitleRule: CourierRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierRollup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierRollupRequiredCodeRule: CourierRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a courier rollup.
    final class CourierRollupValidator {
        var rules: [any CourierRollupRule]

        init(rules: [any CourierRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CourierRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierRollup]) -> [String: [String]] {
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

    static func defaultCourierRollupValidator() -> CourierRollupValidator {
        return CourierRollupValidator(
            rules: [
                CourierRollupRequiredUnitRule(message: "courier rollup needs an entry"),
                CourierRollupTitleLengthRule(maxLength: 64),
                CourierRollupUnitLengthRule(maxLength: 32),
                CourierRollupAllowedCountryRule(allowed: []),
                CourierRollupRequiredTitleRule(message: "courier rollup needs a value"),
                CourierRollupRequiredCodeRule(message: "courier rollup needs an entry"),
            ]
        )
    }
}
