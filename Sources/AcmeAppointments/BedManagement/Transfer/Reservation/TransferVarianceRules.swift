import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer variance must pass. Check returns its problems, or none.
    protocol TransferVarianceRule {
        func check(_ item: TransferVariance) -> [String]
    }

    final class TransferVarianceRequiredLocaleRule: TransferVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferVariance) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferVarianceTitleLengthRule: TransferVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferVariance) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferVarianceCodePrefixRule: TransferVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TransferVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TransferVarianceDiscountRangeRule: TransferVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferVariance) -> [String] {
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

    final class TransferVarianceAllowedCodeRule: TransferVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TransferVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class TransferVarianceActiveGuardRule: TransferVarianceRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: TransferVariance) -> [String] {
            if item.active && (item.attempts > limit) {
                return ["attempts \(item.attempts) exceeds \(limit) while active"]
            }
            return []
        }
    }

    /// Runs every rule of a transfer variance.
    final class TransferVarianceValidator {
        var rules: [any TransferVarianceRule]

        init(rules: [any TransferVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferVariance) -> [String] {
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

        func requireValid(_ item: TransferVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferVariance]) -> [String: [String]] {
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

    static func defaultTransferVarianceValidator() -> TransferVarianceValidator {
        return TransferVarianceValidator(
            rules: [
                TransferVarianceRequiredLocaleRule(message: "transfer variance needs an entry"),
                TransferVarianceTitleLengthRule(maxLength: 80),
                TransferVarianceCodePrefixRule(prefix: "Q"),
                TransferVarianceDiscountRangeRule(min: 8.3, max: 396.0),
                TransferVarianceAllowedCodeRule(allowed: []),
                TransferVarianceActiveGuardRule(limit: 255),
            ]
        )
    }
}
