import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a adaptive claim rollup must pass. Check returns its problems, or none.
    protocol AdaptiveClaimRollupRule {
        func check(_ item: AdaptiveClaimRollup) -> [String]
    }

    final class AdaptiveClaimRollupRequiredExternalRefRule: AdaptiveClaimRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveClaimRollup) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveClaimRollupCodeLengthRule: AdaptiveClaimRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveClaimRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveClaimRollupRequiredNameRule: AdaptiveClaimRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveClaimRollup) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive claim rollup.
    final class AdaptiveClaimRollupValidator {
        var rules: [any AdaptiveClaimRollupRule]

        init(rules: [any AdaptiveClaimRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveClaimRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveClaimRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveClaimRollup]) -> [String: [String]] {
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

    static func defaultAdaptiveClaimRollupValidator() -> AdaptiveClaimRollupValidator {
        return AdaptiveClaimRollupValidator(
            rules: [
                AdaptiveClaimRollupRequiredExternalRefRule(message: "adaptive claim rollup needs an entry"),
                AdaptiveClaimRollupCodeLengthRule(maxLength: 3600),
                AdaptiveClaimRollupRequiredNameRule(message: "adaptive claim rollup needs a value"),
            ]
        )
    }
}
