import AcmePlatform
import Foundation

extension Consent {
    /// A rule a seasonal witness budget must pass. Check returns its problems, or none.
    protocol SeasonalWitnessBudgetRule {
        func check(_ item: SeasonalWitnessBudget) -> [String]
    }

    final class SeasonalWitnessBudgetCodePrefixRule: SeasonalWitnessBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalWitnessBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalWitnessBudgetCodeLengthRule: SeasonalWitnessBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalWitnessBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalWitnessBudgetSourceLengthRule: SeasonalWitnessBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalWitnessBudget) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalWitnessBudgetRequiredChecksumRule: SeasonalWitnessBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalWitnessBudget) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalWitnessBudgetChecksumLengthRule: SeasonalWitnessBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalWitnessBudget) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalWitnessBudgetAllowedCodeRule: SeasonalWitnessBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalWitnessBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal witness budget.
    final class SeasonalWitnessBudgetValidator {
        var rules: [any SeasonalWitnessBudgetRule]

        init(rules: [any SeasonalWitnessBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalWitnessBudget) -> [String] {
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

        func requireValid(_ item: SeasonalWitnessBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalWitnessBudget]) -> [String: [String]] {
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

    static func defaultSeasonalWitnessBudgetValidator() -> SeasonalWitnessBudgetValidator {
        return SeasonalWitnessBudgetValidator(
            rules: [
                SeasonalWitnessBudgetCodePrefixRule(prefix: "Q"),
                SeasonalWitnessBudgetCodeLengthRule(maxLength: 255),
                SeasonalWitnessBudgetSourceLengthRule(maxLength: 1000),
                SeasonalWitnessBudgetRequiredChecksumRule(message: "seasonal witness budget needs this field"),
                SeasonalWitnessBudgetChecksumLengthRule(maxLength: 86400),
                SeasonalWitnessBudgetAllowedCodeRule(allowed: []),
            ]
        )
    }
}
