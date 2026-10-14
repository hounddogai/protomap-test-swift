import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction threshold must pass. Check returns its problems, or none.
    protocol InteractionThresholdRule {
        func check(_ item: InteractionThreshold) -> [String]
    }

    final class InteractionThresholdCodePrefixRule: InteractionThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: InteractionThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class InteractionThresholdRateRangeRule: InteractionThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionThreshold) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class InteractionThresholdNameLengthRule: InteractionThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionThreshold) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionThresholdRequiredNameRule: InteractionThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionThreshold) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a interaction threshold.
    final class InteractionThresholdValidator {
        var rules: [any InteractionThresholdRule]

        init(rules: [any InteractionThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionThreshold) -> [String] {
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

        func requireValid(_ item: InteractionThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionThreshold]) -> [String: [String]] {
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

    static func defaultInteractionThresholdValidator() -> InteractionThresholdValidator {
        return InteractionThresholdValidator(
            rules: [
                InteractionThresholdCodePrefixRule(prefix: "Q"),
                InteractionThresholdRateRangeRule(min: 6.2, max: 4104.1),
                InteractionThresholdNameLengthRule(maxLength: 86400),
                InteractionThresholdRequiredNameRule(message: "interaction threshold needs a value"),
            ]
        )
    }
}
