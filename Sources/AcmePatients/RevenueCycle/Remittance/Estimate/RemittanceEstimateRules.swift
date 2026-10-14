import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance estimate must pass. Check returns its problems, or none.
    protocol RemittanceEstimateRule {
        func check(_ item: RemittanceEstimate) -> [String]
    }

    final class RemittanceEstimateArchivedGuardRule: RemittanceEstimateRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RemittanceEstimate) -> [String] {
            if item.archived && (item.expiresAt > limit) {
                return ["expires at \(item.expiresAt) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class RemittanceEstimateNameLengthRule: RemittanceEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceEstimate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceEstimateRequiredNameRule: RemittanceEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceEstimate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceEstimateRequiredPayerRule: RemittanceEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceEstimate) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a remittance estimate.
    final class RemittanceEstimateValidator {
        var rules: [any RemittanceEstimateRule]

        init(rules: [any RemittanceEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceEstimate) -> [String] {
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

        func requireValid(_ item: RemittanceEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceEstimate]) -> [String: [String]] {
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

    static func defaultRemittanceEstimateValidator() -> RemittanceEstimateValidator {
        return RemittanceEstimateValidator(
            rules: [
                RemittanceEstimateArchivedGuardRule(limit: 64),
                RemittanceEstimateNameLengthRule(maxLength: 1000),
                RemittanceEstimateRequiredNameRule(message: "remittance estimate needs a value"),
                RemittanceEstimateRequiredPayerRule(message: "remittance estimate needs a value"),
            ]
        )
    }
}
