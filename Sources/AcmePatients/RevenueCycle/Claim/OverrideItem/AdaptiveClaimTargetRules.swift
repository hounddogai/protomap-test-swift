import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a adaptive claim target must pass. Check returns its problems, or none.
    protocol AdaptiveClaimTargetRule {
        func check(_ item: AdaptiveClaimTarget) -> [String]
    }

    final class AdaptiveClaimTargetCodeLengthRule: AdaptiveClaimTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveClaimTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveClaimTargetNameLengthRule: AdaptiveClaimTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveClaimTarget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveClaimTargetRequiredNameRule: AdaptiveClaimTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveClaimTarget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive claim target.
    final class AdaptiveClaimTargetValidator {
        var rules: [any AdaptiveClaimTargetRule]

        init(rules: [any AdaptiveClaimTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveClaimTarget) -> [String] {
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

        func requireValid(_ item: AdaptiveClaimTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveClaimTarget]) -> [String: [String]] {
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

    static func defaultAdaptiveClaimTargetValidator() -> AdaptiveClaimTargetValidator {
        return AdaptiveClaimTargetValidator(
            rules: [
                AdaptiveClaimTargetCodeLengthRule(maxLength: 86400),
                AdaptiveClaimTargetNameLengthRule(maxLength: 32),
                AdaptiveClaimTargetRequiredNameRule(message: "adaptive claim target needs a value"),
            ]
        )
    }
}
