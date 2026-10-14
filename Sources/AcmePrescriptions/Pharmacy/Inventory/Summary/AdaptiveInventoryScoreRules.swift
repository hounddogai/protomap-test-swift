import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a adaptive inventory score must pass. Check returns its problems, or none.
    protocol AdaptiveInventoryScoreRule {
        func check(_ item: AdaptiveInventoryScore) -> [String]
    }

    final class AdaptiveInventoryScoreCodePrefixRule: AdaptiveInventoryScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveInventoryScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveInventoryScoreCodeLengthRule: AdaptiveInventoryScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveInventoryScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveInventoryScoreAllowedLabelRule: AdaptiveInventoryScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveInventoryScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive inventory score.
    final class AdaptiveInventoryScoreValidator {
        var rules: [any AdaptiveInventoryScoreRule]

        init(rules: [any AdaptiveInventoryScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveInventoryScore) -> [String] {
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

        func requireValid(_ item: AdaptiveInventoryScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveInventoryScore]) -> [String: [String]] {
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

    static func defaultAdaptiveInventoryScoreValidator() -> AdaptiveInventoryScoreValidator {
        return AdaptiveInventoryScoreValidator(
            rules: [
                AdaptiveInventoryScoreCodePrefixRule(prefix: "ACM"),
                AdaptiveInventoryScoreCodeLengthRule(maxLength: 16),
                AdaptiveInventoryScoreAllowedLabelRule(allowed: ["manual", "weighted"]),
            ]
        )
    }
}
