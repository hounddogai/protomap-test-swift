import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a global goal estimate must pass. Check returns its problems, or none.
    protocol GlobalGoalEstimateRule {
        func check(_ item: GlobalGoalEstimate) -> [String]
    }

    final class GlobalGoalEstimateArchivedGuardRule: GlobalGoalEstimateRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: GlobalGoalEstimate) -> [String] {
            if item.archived && (item.amount > limit) {
                return ["amount \(item.amount) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class GlobalGoalEstimateRequiredChecksumRule: GlobalGoalEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalGoalEstimate) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalGoalEstimateCodePrefixRule: GlobalGoalEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalGoalEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a global goal estimate.
    final class GlobalGoalEstimateValidator {
        var rules: [any GlobalGoalEstimateRule]

        init(rules: [any GlobalGoalEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalGoalEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalGoalEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalGoalEstimate]) -> [String: [String]] {
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

    static func defaultGlobalGoalEstimateValidator() -> GlobalGoalEstimateValidator {
        return GlobalGoalEstimateValidator(
            rules: [
                GlobalGoalEstimateArchivedGuardRule(limit: 7.6),
                GlobalGoalEstimateRequiredChecksumRule(message: "global goal estimate needs this field"),
                GlobalGoalEstimateCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
