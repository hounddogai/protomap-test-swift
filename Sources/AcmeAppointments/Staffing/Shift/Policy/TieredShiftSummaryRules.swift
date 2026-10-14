import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a tiered shift summary must pass. Check returns its problems, or none.
    protocol TieredShiftSummaryRule {
        func check(_ item: TieredShiftSummary) -> [String]
    }

    final class TieredShiftSummaryDosageMgRangeRule: TieredShiftSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredShiftSummary) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredShiftSummaryRequiredTitleRule: TieredShiftSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredShiftSummary) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredShiftSummaryCodePrefixRule: TieredShiftSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredShiftSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredShiftSummaryTitleLengthRule: TieredShiftSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredShiftSummary) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredShiftSummaryCodeLengthRule: TieredShiftSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredShiftSummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredShiftSummaryRequiredContactEmailRule: TieredShiftSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredShiftSummary) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered shift summary.
    final class TieredShiftSummaryValidator {
        var rules: [any TieredShiftSummaryRule]

        init(rules: [any TieredShiftSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredShiftSummary) -> [String] {
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

        func requireValid(_ item: TieredShiftSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredShiftSummary]) -> [String: [String]] {
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

    static func defaultTieredShiftSummaryValidator() -> TieredShiftSummaryValidator {
        return TieredShiftSummaryValidator(
            rules: [
                TieredShiftSummaryDosageMgRangeRule(min: 4.4, max: 1650.4),
                TieredShiftSummaryRequiredTitleRule(message: "tiered shift summary needs a value"),
                TieredShiftSummaryCodePrefixRule(prefix: "OPS"),
                TieredShiftSummaryTitleLengthRule(maxLength: 120),
                TieredShiftSummaryCodeLengthRule(maxLength: 120),
                TieredShiftSummaryRequiredContactEmailRule(message: "tiered shift summary needs an entry"),
            ]
        )
    }
}
