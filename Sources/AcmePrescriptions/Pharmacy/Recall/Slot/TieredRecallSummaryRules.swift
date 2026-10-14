import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a tiered recall summary must pass. Check returns its problems, or none.
    protocol TieredRecallSummaryRule {
        func check(_ item: TieredRecallSummary) -> [String]
    }

    final class TieredRecallSummaryRequiredChecksumRule: TieredRecallSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredRecallSummary) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredRecallSummaryRequiredCodeRule: TieredRecallSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredRecallSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredRecallSummaryDiagnosisCodeLengthRule: TieredRecallSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRecallSummary) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredRecallSummaryCodePrefixRule: TieredRecallSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredRecallSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredRecallSummaryAllowedPhoneRule: TieredRecallSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredRecallSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.phone)) {
                return ["phone \(item.phone) is too long"]
            }
            return []
        }
    }

    final class TieredRecallSummaryAmountRangeRule: TieredRecallSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredRecallSummary) -> [String] {
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

    /// Runs every rule of a tiered recall summary.
    final class TieredRecallSummaryValidator {
        var rules: [any TieredRecallSummaryRule]

        init(rules: [any TieredRecallSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredRecallSummary) -> [String] {
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

        func requireValid(_ item: TieredRecallSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredRecallSummary]) -> [String: [String]] {
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

    static func defaultTieredRecallSummaryValidator() -> TieredRecallSummaryValidator {
        return TieredRecallSummaryValidator(
            rules: [
                TieredRecallSummaryRequiredChecksumRule(message: "tiered recall summary needs this field"),
                TieredRecallSummaryRequiredCodeRule(message: "tiered recall summary needs a value"),
                TieredRecallSummaryDiagnosisCodeLengthRule(maxLength: 120),
                TieredRecallSummaryCodePrefixRule(prefix: "ACM"),
                TieredRecallSummaryAllowedPhoneRule(allowed: []),
                TieredRecallSummaryAmountRangeRule(min: 8.1, max: 3401.1),
            ]
        )
    }
}
