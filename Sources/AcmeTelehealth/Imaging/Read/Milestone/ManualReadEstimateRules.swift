import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a manual read estimate must pass. Check returns its problems, or none.
    protocol ManualReadEstimateRule {
        func check(_ item: ManualReadEstimate) -> [String]
    }

    final class ManualReadEstimateTitleLengthRule: ManualReadEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualReadEstimate) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualReadEstimateRequiredCodeRule: ManualReadEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualReadEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualReadEstimateCodeLengthRule: ManualReadEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualReadEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualReadEstimateRequiredCurrencyRule: ManualReadEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualReadEstimate) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualReadEstimateRequiredTitleRule: ManualReadEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualReadEstimate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual read estimate.
    final class ManualReadEstimateValidator {
        var rules: [any ManualReadEstimateRule]

        init(rules: [any ManualReadEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualReadEstimate) -> [String] {
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

        func requireValid(_ item: ManualReadEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualReadEstimate]) -> [String: [String]] {
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

    static func defaultManualReadEstimateValidator() -> ManualReadEstimateValidator {
        return ManualReadEstimateValidator(
            rules: [
                ManualReadEstimateTitleLengthRule(maxLength: 32),
                ManualReadEstimateRequiredCodeRule(message: "manual read estimate needs this field"),
                ManualReadEstimateCodeLengthRule(maxLength: 255),
                ManualReadEstimateRequiredCurrencyRule(message: "manual read estimate needs this field"),
                ManualReadEstimateRequiredTitleRule(message: "manual read estimate needs a value"),
            ]
        )
    }
}
