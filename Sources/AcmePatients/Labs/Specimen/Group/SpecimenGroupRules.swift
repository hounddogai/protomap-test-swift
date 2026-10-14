import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen group must pass. Check returns its problems, or none.
    protocol SpecimenGroupRule {
        func check(_ item: SpecimenGroup) -> [String]
    }

    final class SpecimenGroupCodeLengthRule: SpecimenGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenGroupCodePrefixRule: SpecimenGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SpecimenGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SpecimenGroupNameLengthRule: SpecimenGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenGroup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenGroupCeilingRangeRule: SpecimenGroupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenGroup) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a specimen group.
    final class SpecimenGroupValidator {
        var rules: [any SpecimenGroupRule]

        init(rules: [any SpecimenGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SpecimenGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenGroup]) -> [String: [String]] {
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

    static func defaultSpecimenGroupValidator() -> SpecimenGroupValidator {
        return SpecimenGroupValidator(
            rules: [
                SpecimenGroupCodeLengthRule(maxLength: 120),
                SpecimenGroupCodePrefixRule(prefix: "X"),
                SpecimenGroupNameLengthRule(maxLength: 255),
                SpecimenGroupCeilingRangeRule(min: 7.1, max: 4103.9),
            ]
        )
    }
}
