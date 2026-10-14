import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a default program estimate must pass. Check returns its problems, or none.
    protocol DefaultProgramEstimateRule {
        func check(_ item: DefaultProgramEstimate) -> [String]
    }

    final class DefaultProgramEstimateSummaryLengthRule: DefaultProgramEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultProgramEstimate) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultProgramEstimateCodePrefixRule: DefaultProgramEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultProgramEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultProgramEstimateRequiredNameRule: DefaultProgramEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultProgramEstimate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultProgramEstimateRequiredCodeRule: DefaultProgramEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultProgramEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default program estimate.
    final class DefaultProgramEstimateValidator {
        var rules: [any DefaultProgramEstimateRule]

        init(rules: [any DefaultProgramEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultProgramEstimate) -> [String] {
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

        func requireValid(_ item: DefaultProgramEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultProgramEstimate]) -> [String: [String]] {
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

    static func defaultDefaultProgramEstimateValidator() -> DefaultProgramEstimateValidator {
        return DefaultProgramEstimateValidator(
            rules: [
                DefaultProgramEstimateSummaryLengthRule(maxLength: 1000),
                DefaultProgramEstimateCodePrefixRule(prefix: "X"),
                DefaultProgramEstimateRequiredNameRule(message: "default program estimate needs this field"),
                DefaultProgramEstimateRequiredCodeRule(message: "default program estimate needs a value"),
            ]
        )
    }
}
