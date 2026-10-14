import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim notice must pass. Check returns its problems, or none.
    protocol ClaimNoticeRule {
        func check(_ item: ClaimNotice) -> [String]
    }

    final class ClaimNoticeRequiredTimezoneRule: ClaimNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimNotice) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimNoticeCodePrefixRule: ClaimNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ClaimNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ClaimNoticeAmountRangeRule: ClaimNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimNotice) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClaimNoticeRequiredCodeRule: ClaimNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimNoticeRequiredChecksumRule: ClaimNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimNotice) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimNoticeRequiredTitleRule: ClaimNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimNotice) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a claim notice.
    final class ClaimNoticeValidator {
        var rules: [any ClaimNoticeRule]

        init(rules: [any ClaimNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimNotice) -> [String] {
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

        func requireValid(_ item: ClaimNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimNotice]) -> [String: [String]] {
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

    static func defaultClaimNoticeValidator() -> ClaimNoticeValidator {
        return ClaimNoticeValidator(
            rules: [
                ClaimNoticeRequiredTimezoneRule(message: "claim notice needs this field"),
                ClaimNoticeCodePrefixRule(prefix: "ACM"),
                ClaimNoticeAmountRangeRule(min: 1.8, max: 4209.0),
                ClaimNoticeRequiredCodeRule(message: "claim notice needs an entry"),
                ClaimNoticeRequiredChecksumRule(message: "claim notice needs this field"),
                ClaimNoticeRequiredTitleRule(message: "claim notice needs this field"),
            ]
        )
    }
}
