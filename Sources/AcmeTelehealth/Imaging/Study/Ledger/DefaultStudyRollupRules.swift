import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a default study rollup must pass. Check returns its problems, or none.
    protocol DefaultStudyRollupRule {
        func check(_ item: DefaultStudyRollup) -> [String]
    }

    final class DefaultStudyRollupCodePrefixRule: DefaultStudyRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultStudyRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultStudyRollupCodeLengthRule: DefaultStudyRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultStudyRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultStudyRollupRequiredCodeRule: DefaultStudyRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultStudyRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultStudyRollupFloorValueRangeRule: DefaultStudyRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultStudyRollup) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultStudyRollupRequiredUnitRule: DefaultStudyRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultStudyRollup) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultStudyRollupUnitLengthRule: DefaultStudyRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultStudyRollup) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default study rollup.
    final class DefaultStudyRollupValidator {
        var rules: [any DefaultStudyRollupRule]

        init(rules: [any DefaultStudyRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultStudyRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultStudyRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultStudyRollup]) -> [String: [String]] {
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

    static func defaultDefaultStudyRollupValidator() -> DefaultStudyRollupValidator {
        return DefaultStudyRollupValidator(
            rules: [
                DefaultStudyRollupCodePrefixRule(prefix: "Q"),
                DefaultStudyRollupCodeLengthRule(maxLength: 255),
                DefaultStudyRollupRequiredCodeRule(message: "default study rollup needs a value"),
                DefaultStudyRollupFloorValueRangeRule(min: 6.6, max: 4600.0),
                DefaultStudyRollupRequiredUnitRule(message: "default study rollup needs a value"),
                DefaultStudyRollupUnitLengthRule(maxLength: 86400),
            ]
        )
    }
}
