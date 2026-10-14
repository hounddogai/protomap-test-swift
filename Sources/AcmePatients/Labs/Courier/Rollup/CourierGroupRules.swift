import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier group must pass. Check returns its problems, or none.
    protocol CourierGroupRule {
        func check(_ item: CourierGroup) -> [String]
    }

    final class CourierGroupBedLengthRule: CourierGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierGroup) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CourierGroupCodePrefixRule: CourierGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CourierGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CourierGroupCodeLengthRule: CourierGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a courier group.
    final class CourierGroupValidator {
        var rules: [any CourierGroupRule]

        init(rules: [any CourierGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CourierGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierGroup]) -> [String: [String]] {
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

    static func defaultCourierGroupValidator() -> CourierGroupValidator {
        return CourierGroupValidator(
            rules: [
                CourierGroupBedLengthRule(maxLength: 16),
                CourierGroupCodePrefixRule(prefix: "OPS"),
                CourierGroupCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
