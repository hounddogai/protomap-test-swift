import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement estimate must pass. Check returns its problems, or none.
    protocol StatementEstimateRule {
        func check(_ item: StatementEstimate) -> [String]
    }

    final class StatementEstimateDiagnosisCodeLengthRule: StatementEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementEstimate) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementEstimatePriorityRangeRule: StatementEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementEstimate) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StatementEstimateExpiresAtRangeRule: StatementEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementEstimate) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StatementEstimateCodePrefixRule: StatementEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StatementEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StatementEstimateCodeLengthRule: StatementEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementEstimateArchivedGuardRule: StatementEstimateRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: StatementEstimate) -> [String] {
            if item.archived && (item.priority > limit) {
                return ["priority \(item.priority) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a statement estimate.
    final class StatementEstimateValidator {
        var rules: [any StatementEstimateRule]

        init(rules: [any StatementEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementEstimate) -> [String] {
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

        func requireValid(_ item: StatementEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementEstimate]) -> [String: [String]] {
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

    static func defaultStatementEstimateValidator() -> StatementEstimateValidator {
        return StatementEstimateValidator(
            rules: [
                StatementEstimateDiagnosisCodeLengthRule(maxLength: 255),
                StatementEstimatePriorityRangeRule(min: 16, max: 3600),
                StatementEstimateExpiresAtRangeRule(min: 64, max: 80),
                StatementEstimateCodePrefixRule(prefix: "Q"),
                StatementEstimateCodeLengthRule(maxLength: 64),
                StatementEstimateArchivedGuardRule(limit: 120),
            ]
        )
    }
}
