import AcmePlatform
import Foundation

extension Consent {
    /// A rule a default proxy score must pass. Check returns its problems, or none.
    protocol DefaultProxyScoreRule {
        func check(_ item: DefaultProxyScore) -> [String]
    }

    final class DefaultProxyScoreFloorValueRangeRule: DefaultProxyScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultProxyScore) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultProxyScoreCodePrefixRule: DefaultProxyScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultProxyScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultProxyScoreRequiredCodeRule: DefaultProxyScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultProxyScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultProxyScoreCodeLengthRule: DefaultProxyScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultProxyScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultProxyScoreRequiredContactEmailRule: DefaultProxyScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultProxyScore) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default proxy score.
    final class DefaultProxyScoreValidator {
        var rules: [any DefaultProxyScoreRule]

        init(rules: [any DefaultProxyScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultProxyScore) -> [String] {
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

        func requireValid(_ item: DefaultProxyScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultProxyScore]) -> [String: [String]] {
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

    static func defaultDefaultProxyScoreValidator() -> DefaultProxyScoreValidator {
        return DefaultProxyScoreValidator(
            rules: [
                DefaultProxyScoreFloorValueRangeRule(min: 3.0, max: 4816.6),
                DefaultProxyScoreCodePrefixRule(prefix: "REF"),
                DefaultProxyScoreRequiredCodeRule(message: "default proxy score needs this field"),
                DefaultProxyScoreCodeLengthRule(maxLength: 16),
                DefaultProxyScoreRequiredContactEmailRule(message: "default proxy score needs an entry"),
            ]
        )
    }
}
