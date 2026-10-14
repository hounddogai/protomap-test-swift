import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a pending denial variance must pass. Check returns its problems, or none.
    protocol PendingDenialVarianceRule {
        func check(_ item: PendingDenialVariance) -> [String]
    }

    final class PendingDenialVarianceCodeLengthRule: PendingDenialVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingDenialVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingDenialVarianceRequiredCodeRule: PendingDenialVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingDenialVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingDenialVarianceUpdatedAtRangeRule: PendingDenialVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingDenialVariance) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingDenialVarianceRequiredTitleRule: PendingDenialVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingDenialVariance) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingDenialVarianceLimitRangeRule: PendingDenialVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingDenialVariance) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingDenialVarianceAllowedCodeRule: PendingDenialVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingDenialVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a pending denial variance.
    final class PendingDenialVarianceValidator {
        var rules: [any PendingDenialVarianceRule]

        init(rules: [any PendingDenialVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingDenialVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingDenialVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingDenialVariance]) -> [String: [String]] {
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

    static func defaultPendingDenialVarianceValidator() -> PendingDenialVarianceValidator {
        return PendingDenialVarianceValidator(
            rules: [
                PendingDenialVarianceCodeLengthRule(maxLength: 86400),
                PendingDenialVarianceRequiredCodeRule(message: "pending denial variance needs an entry"),
                PendingDenialVarianceUpdatedAtRangeRule(min: 64, max: 120),
                PendingDenialVarianceRequiredTitleRule(message: "pending denial variance needs an entry"),
                PendingDenialVarianceLimitRangeRule(min: 64, max: 255),
                PendingDenialVarianceAllowedCodeRule(allowed: []),
            ]
        )
    }
}
