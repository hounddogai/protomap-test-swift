import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score estimate must pass. Check returns its problems, or none.
    protocol RiskScoreEstimateRule {
        func check(_ item: RiskScoreEstimate) -> [String]
    }

    final class RiskScoreEstimateRequiredCodeRule: RiskScoreEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreEstimateWindowDaysRangeRule: RiskScoreEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreEstimate) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RiskScoreEstimateTitleLengthRule: RiskScoreEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreEstimate) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreEstimateRevisionRangeRule: RiskScoreEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreEstimate) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RiskScoreEstimateOwnerIDLengthRule: RiskScoreEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreEstimate) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score estimate.
    final class RiskScoreEstimateValidator {
        var rules: [any RiskScoreEstimateRule]

        init(rules: [any RiskScoreEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreEstimate) -> [String] {
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

        func requireValid(_ item: RiskScoreEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreEstimate]) -> [String: [String]] {
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

    static func defaultRiskScoreEstimateValidator() -> RiskScoreEstimateValidator {
        return RiskScoreEstimateValidator(
            rules: [
                RiskScoreEstimateRequiredCodeRule(message: "risk score estimate needs this field"),
                RiskScoreEstimateWindowDaysRangeRule(min: 80, max: 86400),
                RiskScoreEstimateTitleLengthRule(maxLength: 32),
                RiskScoreEstimateRevisionRangeRule(min: 64, max: 3600),
                RiskScoreEstimateOwnerIDLengthRule(maxLength: 64),
            ]
        )
    }
}
