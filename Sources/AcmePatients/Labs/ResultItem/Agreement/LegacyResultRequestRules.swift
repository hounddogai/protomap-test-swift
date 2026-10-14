import AcmePlatform
import Foundation

extension Labs {
    /// A rule a legacy result request must pass. Check returns its problems, or none.
    protocol LegacyResultRequestRule {
        func check(_ item: LegacyResultRequest) -> [String]
    }

    final class LegacyResultRequestExpiresAtRangeRule: LegacyResultRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyResultRequest) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyResultRequestCeilingRangeRule: LegacyResultRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyResultRequest) -> [String] {
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

    final class LegacyResultRequestDurationMinutesRangeRule: LegacyResultRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyResultRequest) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyResultRequestRequiredTitleRule: LegacyResultRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyResultRequest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyResultRequestCodePrefixRule: LegacyResultRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyResultRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyResultRequestCodeLengthRule: LegacyResultRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyResultRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy result request.
    final class LegacyResultRequestValidator {
        var rules: [any LegacyResultRequestRule]

        init(rules: [any LegacyResultRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyResultRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyResultRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyResultRequest]) -> [String: [String]] {
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

    static func defaultLegacyResultRequestValidator() -> LegacyResultRequestValidator {
        return LegacyResultRequestValidator(
            rules: [
                LegacyResultRequestExpiresAtRangeRule(min: 120, max: 3600),
                LegacyResultRequestCeilingRangeRule(min: 0.9, max: 3909.1),
                LegacyResultRequestDurationMinutesRangeRule(min: 32, max: 1000),
                LegacyResultRequestRequiredTitleRule(message: "legacy result request needs a value"),
                LegacyResultRequestCodePrefixRule(prefix: "X"),
                LegacyResultRequestCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
