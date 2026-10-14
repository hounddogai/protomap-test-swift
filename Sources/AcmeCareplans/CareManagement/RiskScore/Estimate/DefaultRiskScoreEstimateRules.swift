import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a default risk score estimate must pass. Check returns its problems, or none.
    protocol DefaultRiskScoreEstimateRule {
        func check(_ item: DefaultRiskScoreEstimate) -> [String]
    }

    final class DefaultRiskScoreEstimateRequiredEncounterIDRule: DefaultRiskScoreEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultRiskScoreEstimate) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultRiskScoreEstimateCodeLengthRule: DefaultRiskScoreEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRiskScoreEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultRiskScoreEstimateUpdatedAtRangeRule: DefaultRiskScoreEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultRiskScoreEstimate) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultRiskScoreEstimateEncounterIDLengthRule: DefaultRiskScoreEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRiskScoreEstimate) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultRiskScoreEstimateRequiredCodeRule: DefaultRiskScoreEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultRiskScoreEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultRiskScoreEstimateArchivedGuardRule: DefaultRiskScoreEstimateRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: DefaultRiskScoreEstimate) -> [String] {
            if item.archived && (item.updatedAt > limit) {
                return ["updated at \(item.updatedAt) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a default risk score estimate.
    final class DefaultRiskScoreEstimateValidator {
        var rules: [any DefaultRiskScoreEstimateRule]

        init(rules: [any DefaultRiskScoreEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultRiskScoreEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultRiskScoreEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultRiskScoreEstimate]) -> [String: [String]] {
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

    static func defaultDefaultRiskScoreEstimateValidator() -> DefaultRiskScoreEstimateValidator {
        return DefaultRiskScoreEstimateValidator(
            rules: [
                DefaultRiskScoreEstimateRequiredEncounterIDRule(
                    message: "default risk score estimate needs this field"
                ),
                DefaultRiskScoreEstimateCodeLengthRule(maxLength: 3600),
                DefaultRiskScoreEstimateUpdatedAtRangeRule(min: 120, max: 120),
                DefaultRiskScoreEstimateEncounterIDLengthRule(maxLength: 80),
                DefaultRiskScoreEstimateRequiredCodeRule(message: "default risk score estimate needs this field"),
                DefaultRiskScoreEstimateArchivedGuardRule(limit: 32),
            ]
        )
    }
}
