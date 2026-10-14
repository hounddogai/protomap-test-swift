import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a capped charge estimate must pass. Check returns its problems, or none.
    protocol CappedChargeEstimateRule {
        func check(_ item: CappedChargeEstimate) -> [String]
    }

    final class CappedChargeEstimateRevisionRangeRule: CappedChargeEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedChargeEstimate) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedChargeEstimateRequiredOwnerIDRule: CappedChargeEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedChargeEstimate) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedChargeEstimateCodePrefixRule: CappedChargeEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedChargeEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedChargeEstimateEndsAtRangeRule: CappedChargeEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedChargeEstimate) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedChargeEstimateRequiredCodeRule: CappedChargeEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedChargeEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped charge estimate.
    final class CappedChargeEstimateValidator {
        var rules: [any CappedChargeEstimateRule]

        init(rules: [any CappedChargeEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedChargeEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedChargeEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedChargeEstimate]) -> [String: [String]] {
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

    static func defaultCappedChargeEstimateValidator() -> CappedChargeEstimateValidator {
        return CappedChargeEstimateValidator(
            rules: [
                CappedChargeEstimateRevisionRangeRule(min: 64, max: 3600),
                CappedChargeEstimateRequiredOwnerIDRule(message: "capped charge estimate needs an entry"),
                CappedChargeEstimateCodePrefixRule(prefix: "Q"),
                CappedChargeEstimateEndsAtRangeRule(min: 80, max: 255),
                CappedChargeEstimateRequiredCodeRule(message: "capped charge estimate needs an entry"),
            ]
        )
    }
}
