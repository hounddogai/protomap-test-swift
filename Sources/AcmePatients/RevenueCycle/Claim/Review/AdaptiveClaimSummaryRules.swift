import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a adaptive claim summary must pass. Check returns its problems, or none.
    protocol AdaptiveClaimSummaryRule {
        func check(_ item: AdaptiveClaimSummary) -> [String]
    }

    final class AdaptiveClaimSummaryTitleLengthRule: AdaptiveClaimSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveClaimSummary) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveClaimSummaryCodePrefixRule: AdaptiveClaimSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveClaimSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveClaimSummaryRequiredCodeRule: AdaptiveClaimSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveClaimSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive claim summary.
    final class AdaptiveClaimSummaryValidator {
        var rules: [any AdaptiveClaimSummaryRule]

        init(rules: [any AdaptiveClaimSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveClaimSummary) -> [String] {
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

        func requireValid(_ item: AdaptiveClaimSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveClaimSummary]) -> [String: [String]] {
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

    static func defaultAdaptiveClaimSummaryValidator() -> AdaptiveClaimSummaryValidator {
        return AdaptiveClaimSummaryValidator(
            rules: [
                AdaptiveClaimSummaryTitleLengthRule(maxLength: 32),
                AdaptiveClaimSummaryCodePrefixRule(prefix: "REF"),
                AdaptiveClaimSummaryRequiredCodeRule(message: "adaptive claim summary needs a value"),
            ]
        )
    }
}
