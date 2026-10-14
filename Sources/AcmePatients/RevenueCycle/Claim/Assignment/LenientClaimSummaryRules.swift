import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a lenient claim summary must pass. Check returns its problems, or none.
    protocol LenientClaimSummaryRule {
        func check(_ item: LenientClaimSummary) -> [String]
    }

    final class LenientClaimSummaryChecksumLengthRule: LenientClaimSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientClaimSummary) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientClaimSummaryRequiredNameRule: LenientClaimSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientClaimSummary) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientClaimSummaryCodePrefixRule: LenientClaimSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientClaimSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientClaimSummaryContactEmailLengthRule: LenientClaimSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientClaimSummary) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientClaimSummaryQuantityRangeRule: LenientClaimSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientClaimSummary) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientClaimSummaryRequiredContactEmailRule: LenientClaimSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientClaimSummary) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient claim summary.
    final class LenientClaimSummaryValidator {
        var rules: [any LenientClaimSummaryRule]

        init(rules: [any LenientClaimSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientClaimSummary) -> [String] {
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

        func requireValid(_ item: LenientClaimSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientClaimSummary]) -> [String: [String]] {
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

    static func defaultLenientClaimSummaryValidator() -> LenientClaimSummaryValidator {
        return LenientClaimSummaryValidator(
            rules: [
                LenientClaimSummaryChecksumLengthRule(maxLength: 16),
                LenientClaimSummaryRequiredNameRule(message: "lenient claim summary needs an entry"),
                LenientClaimSummaryCodePrefixRule(prefix: "OPS"),
                LenientClaimSummaryContactEmailLengthRule(maxLength: 86400),
                LenientClaimSummaryQuantityRangeRule(min: 16, max: 86400),
                LenientClaimSummaryRequiredContactEmailRule(message: "lenient claim summary needs a value"),
            ]
        )
    }
}
