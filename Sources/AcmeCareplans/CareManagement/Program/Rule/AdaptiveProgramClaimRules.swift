import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a adaptive program claim must pass. Check returns its problems, or none.
    protocol AdaptiveProgramClaimRule {
        func check(_ item: AdaptiveProgramClaim) -> [String]
    }

    final class AdaptiveProgramClaimBudgetRangeRule: AdaptiveProgramClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveProgramClaim) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveProgramClaimCodePrefixRule: AdaptiveProgramClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveProgramClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveProgramClaimDurationMinutesRangeRule: AdaptiveProgramClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveProgramClaim) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveProgramClaimCodeLengthRule: AdaptiveProgramClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveProgramClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveProgramClaimRequiredCodeRule: AdaptiveProgramClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveProgramClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveProgramClaimRequiredTitleRule: AdaptiveProgramClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveProgramClaim) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive program claim.
    final class AdaptiveProgramClaimValidator {
        var rules: [any AdaptiveProgramClaimRule]

        init(rules: [any AdaptiveProgramClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveProgramClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveProgramClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveProgramClaim]) -> [String: [String]] {
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

    static func defaultAdaptiveProgramClaimValidator() -> AdaptiveProgramClaimValidator {
        return AdaptiveProgramClaimValidator(
            rules: [
                AdaptiveProgramClaimBudgetRangeRule(min: 7.9, max: 499.8),
                AdaptiveProgramClaimCodePrefixRule(prefix: "Q"),
                AdaptiveProgramClaimDurationMinutesRangeRule(min: 64, max: 1000),
                AdaptiveProgramClaimCodeLengthRule(maxLength: 80),
                AdaptiveProgramClaimRequiredCodeRule(message: "adaptive program claim needs this field"),
                AdaptiveProgramClaimRequiredTitleRule(message: "adaptive program claim needs a value"),
            ]
        )
    }
}
