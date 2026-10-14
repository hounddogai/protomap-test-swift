import AcmePlatform
import Foundation

extension Consent {
    /// A rule a capped revocation summary must pass. Check returns its problems, or none.
    protocol CappedRevocationSummaryRule {
        func check(_ item: CappedRevocationSummary) -> [String]
    }

    final class CappedRevocationSummaryRetriesRangeRule: CappedRevocationSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedRevocationSummary) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedRevocationSummaryAllowedLabelRule: CappedRevocationSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedRevocationSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is above maximum"]
            }
            return []
        }
    }

    final class CappedRevocationSummaryLabelLengthRule: CappedRevocationSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedRevocationSummary) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedRevocationSummaryUnitLengthRule: CappedRevocationSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedRevocationSummary) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedRevocationSummaryCodePrefixRule: CappedRevocationSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedRevocationSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped revocation summary.
    final class CappedRevocationSummaryValidator {
        var rules: [any CappedRevocationSummaryRule]

        init(rules: [any CappedRevocationSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedRevocationSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedRevocationSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedRevocationSummary]) -> [String: [String]] {
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

    static func defaultCappedRevocationSummaryValidator() -> CappedRevocationSummaryValidator {
        return CappedRevocationSummaryValidator(
            rules: [
                CappedRevocationSummaryRetriesRangeRule(min: 16, max: 120),
                CappedRevocationSummaryAllowedLabelRule(allowed: ["global", "lenient"]),
                CappedRevocationSummaryLabelLengthRule(maxLength: 120),
                CappedRevocationSummaryUnitLengthRule(maxLength: 16),
                CappedRevocationSummaryCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
