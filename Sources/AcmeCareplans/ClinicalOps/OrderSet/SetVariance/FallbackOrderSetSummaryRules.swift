import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a fallback order set summary must pass. Check returns its problems, or none.
    protocol FallbackOrderSetSummaryRule {
        func check(_ item: FallbackOrderSetSummary) -> [String]
    }

    final class FallbackOrderSetSummaryTitleLengthRule: FallbackOrderSetSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackOrderSetSummary) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackOrderSetSummaryRequiredTitleRule: FallbackOrderSetSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackOrderSetSummary) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackOrderSetSummaryAmountRangeRule: FallbackOrderSetSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackOrderSetSummary) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackOrderSetSummaryRequiredClinicianIDRule: FallbackOrderSetSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackOrderSetSummary) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackOrderSetSummaryCodeLengthRule: FallbackOrderSetSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackOrderSetSummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback order set summary.
    final class FallbackOrderSetSummaryValidator {
        var rules: [any FallbackOrderSetSummaryRule]

        init(rules: [any FallbackOrderSetSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackOrderSetSummary) -> [String] {
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

        func requireValid(_ item: FallbackOrderSetSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackOrderSetSummary]) -> [String: [String]] {
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

    static func defaultFallbackOrderSetSummaryValidator() -> FallbackOrderSetSummaryValidator {
        return FallbackOrderSetSummaryValidator(
            rules: [
                FallbackOrderSetSummaryTitleLengthRule(maxLength: 16),
                FallbackOrderSetSummaryRequiredTitleRule(message: "fallback order set summary needs an entry"),
                FallbackOrderSetSummaryAmountRangeRule(min: 0.9, max: 3168.5),
                FallbackOrderSetSummaryRequiredClinicianIDRule(message: "fallback order set summary needs an entry"),
                FallbackOrderSetSummaryCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
