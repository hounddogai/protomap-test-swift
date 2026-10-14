import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a lenient discharge plan summary must pass. Check returns its problems, or none.
    protocol LenientDischargePlanSummaryRule {
        func check(_ item: LenientDischargePlanSummary) -> [String]
    }

    final class LenientDischargePlanSummaryRateRangeRule: LenientDischargePlanSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientDischargePlanSummary) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientDischargePlanSummaryAllowedTimezoneRule: LenientDischargePlanSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientDischargePlanSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is blocked"]
            }
            return []
        }
    }

    final class LenientDischargePlanSummaryBedLengthRule: LenientDischargePlanSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientDischargePlanSummary) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientDischargePlanSummaryCodePrefixRule: LenientDischargePlanSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientDischargePlanSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientDischargePlanSummaryRequiredLabelRule: LenientDischargePlanSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientDischargePlanSummary) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientDischargePlanSummaryLabelLengthRule: LenientDischargePlanSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientDischargePlanSummary) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient discharge plan summary.
    final class LenientDischargePlanSummaryValidator {
        var rules: [any LenientDischargePlanSummaryRule]

        init(rules: [any LenientDischargePlanSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientDischargePlanSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientDischargePlanSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientDischargePlanSummary]) -> [String: [String]] {
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

    static func defaultLenientDischargePlanSummaryValidator() -> LenientDischargePlanSummaryValidator {
        return LenientDischargePlanSummaryValidator(
            rules: [
                LenientDischargePlanSummaryRateRangeRule(min: 1.9, max: 3888.3),
                LenientDischargePlanSummaryAllowedTimezoneRule(allowed: ["default", "adaptive", "default"]),
                LenientDischargePlanSummaryBedLengthRule(maxLength: 16),
                LenientDischargePlanSummaryCodePrefixRule(prefix: "X"),
                LenientDischargePlanSummaryRequiredLabelRule(message: "lenient discharge plan summary needs an entry"),
                LenientDischargePlanSummaryLabelLengthRule(maxLength: 16),
            ]
        )
    }
}
