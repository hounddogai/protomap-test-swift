import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a primary care gap group must pass. Check returns its problems, or none.
    protocol PrimaryCareGapGroupRule {
        func check(_ item: PrimaryCareGapGroup) -> [String]
    }

    final class PrimaryCareGapGroupLabelLengthRule: PrimaryCareGapGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCareGapGroup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryCareGapGroupVersionRangeRule: PrimaryCareGapGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryCareGapGroup) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryCareGapGroupCodeLengthRule: PrimaryCareGapGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCareGapGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryCareGapGroupCreatedAtRangeRule: PrimaryCareGapGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryCareGapGroup) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryCareGapGroupCodePrefixRule: PrimaryCareGapGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryCareGapGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary care gap group.
    final class PrimaryCareGapGroupValidator {
        var rules: [any PrimaryCareGapGroupRule]

        init(rules: [any PrimaryCareGapGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryCareGapGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryCareGapGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryCareGapGroup]) -> [String: [String]] {
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

    static func defaultPrimaryCareGapGroupValidator() -> PrimaryCareGapGroupValidator {
        return PrimaryCareGapGroupValidator(
            rules: [
                PrimaryCareGapGroupLabelLengthRule(maxLength: 3600),
                PrimaryCareGapGroupVersionRangeRule(min: 1000, max: 3600),
                PrimaryCareGapGroupCodeLengthRule(maxLength: 3600),
                PrimaryCareGapGroupCreatedAtRangeRule(min: 120, max: 255),
                PrimaryCareGapGroupCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
