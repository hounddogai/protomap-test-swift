import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap override must pass. Check returns its problems, or none.
    protocol CareGapOverrideRule {
        func check(_ item: CareGapOverride) -> [String]
    }

    final class CareGapOverrideTitleLengthRule: CareGapOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapOverride) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapOverrideRequiredCodeRule: CareGapOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapOverrideRevisionRangeRule: CareGapOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapOverride) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareGapOverrideCodePrefixRule: CareGapOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CareGapOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a care gap override.
    final class CareGapOverrideValidator {
        var rules: [any CareGapOverrideRule]

        init(rules: [any CareGapOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareGapOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapOverride]) -> [String: [String]] {
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

    static func defaultCareGapOverrideValidator() -> CareGapOverrideValidator {
        return CareGapOverrideValidator(
            rules: [
                CareGapOverrideTitleLengthRule(maxLength: 64),
                CareGapOverrideRequiredCodeRule(message: "care gap override needs a value"),
                CareGapOverrideRevisionRangeRule(min: 16, max: 64),
                CareGapOverrideCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
