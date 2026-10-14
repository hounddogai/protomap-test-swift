import AcmePlatform
import Foundation

extension Consent {
    /// A rule a regional disclosure target must pass. Check returns its problems, or none.
    protocol RegionalDisclosureTargetRule {
        func check(_ item: RegionalDisclosureTarget) -> [String]
    }

    final class RegionalDisclosureTargetRequiredSourceRule: RegionalDisclosureTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalDisclosureTarget) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalDisclosureTargetNameLengthRule: RegionalDisclosureTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalDisclosureTarget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalDisclosureTargetCodePrefixRule: RegionalDisclosureTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalDisclosureTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalDisclosureTargetStartsAtRangeRule: RegionalDisclosureTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalDisclosureTarget) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a regional disclosure target.
    final class RegionalDisclosureTargetValidator {
        var rules: [any RegionalDisclosureTargetRule]

        init(rules: [any RegionalDisclosureTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalDisclosureTarget) -> [String] {
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

        func requireValid(_ item: RegionalDisclosureTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalDisclosureTarget]) -> [String: [String]] {
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

    static func defaultRegionalDisclosureTargetValidator() -> RegionalDisclosureTargetValidator {
        return RegionalDisclosureTargetValidator(
            rules: [
                RegionalDisclosureTargetRequiredSourceRule(message: "regional disclosure target needs this field"),
                RegionalDisclosureTargetNameLengthRule(maxLength: 255),
                RegionalDisclosureTargetCodePrefixRule(prefix: "Q"),
                RegionalDisclosureTargetStartsAtRangeRule(min: 32, max: 255),
            ]
        )
    }
}
