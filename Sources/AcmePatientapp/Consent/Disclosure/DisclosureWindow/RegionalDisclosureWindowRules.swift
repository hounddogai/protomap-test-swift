import AcmePlatform
import Foundation

extension Consent {
    /// A rule a regional disclosure window must pass. Check returns its problems, or none.
    protocol RegionalDisclosureWindowRule {
        func check(_ item: RegionalDisclosureWindow) -> [String]
    }

    final class RegionalDisclosureWindowTitleLengthRule: RegionalDisclosureWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalDisclosureWindow) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalDisclosureWindowCodePrefixRule: RegionalDisclosureWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalDisclosureWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalDisclosureWindowRateRangeRule: RegionalDisclosureWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalDisclosureWindow) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalDisclosureWindowCodeLengthRule: RegionalDisclosureWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalDisclosureWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalDisclosureWindowRequiredChannelRule: RegionalDisclosureWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalDisclosureWindow) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional disclosure window.
    final class RegionalDisclosureWindowValidator {
        var rules: [any RegionalDisclosureWindowRule]

        init(rules: [any RegionalDisclosureWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalDisclosureWindow) -> [String] {
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

        func requireValid(_ item: RegionalDisclosureWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalDisclosureWindow]) -> [String: [String]] {
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

    static func defaultRegionalDisclosureWindowValidator() -> RegionalDisclosureWindowValidator {
        return RegionalDisclosureWindowValidator(
            rules: [
                RegionalDisclosureWindowTitleLengthRule(maxLength: 120),
                RegionalDisclosureWindowCodePrefixRule(prefix: "ACM"),
                RegionalDisclosureWindowRateRangeRule(min: 0.2, max: 2130.8),
                RegionalDisclosureWindowCodeLengthRule(maxLength: 32),
                RegionalDisclosureWindowRequiredChannelRule(message: "regional disclosure window needs a value"),
            ]
        )
    }
}
