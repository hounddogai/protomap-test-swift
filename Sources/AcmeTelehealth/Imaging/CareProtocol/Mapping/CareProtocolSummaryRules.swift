import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol summary must pass. Check returns its problems, or none.
    protocol CareProtocolSummaryRule {
        func check(_ item: CareProtocolSummary) -> [String]
    }

    final class CareProtocolSummaryCodeLengthRule: CareProtocolSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolSummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolSummaryDiscountRangeRule: CareProtocolSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolSummary) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareProtocolSummaryStartsAtRangeRule: CareProtocolSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolSummary) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareProtocolSummaryLabelLengthRule: CareProtocolSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolSummary) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolSummaryRequiredCodeRule: CareProtocolSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolSummaryCodePrefixRule: CareProtocolSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CareProtocolSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol summary.
    final class CareProtocolSummaryValidator {
        var rules: [any CareProtocolSummaryRule]

        init(rules: [any CareProtocolSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolSummary]) -> [String: [String]] {
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

    static func defaultCareProtocolSummaryValidator() -> CareProtocolSummaryValidator {
        return CareProtocolSummaryValidator(
            rules: [
                CareProtocolSummaryCodeLengthRule(maxLength: 120),
                CareProtocolSummaryDiscountRangeRule(min: 4.5, max: 1960.7),
                CareProtocolSummaryStartsAtRangeRule(min: 80, max: 120),
                CareProtocolSummaryLabelLengthRule(maxLength: 86400),
                CareProtocolSummaryRequiredCodeRule(message: "care protocol summary needs a value"),
                CareProtocolSummaryCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
