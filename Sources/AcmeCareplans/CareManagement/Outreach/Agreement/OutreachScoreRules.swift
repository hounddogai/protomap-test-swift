import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach score must pass. Check returns its problems, or none.
    protocol OutreachScoreRule {
        func check(_ item: OutreachScore) -> [String]
    }

    final class OutreachScoreFloorValueRangeRule: OutreachScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachScore) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OutreachScoreRequiredBedRule: OutreachScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachScore) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachScoreDiscountRangeRule: OutreachScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachScore) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a outreach score.
    final class OutreachScoreValidator {
        var rules: [any OutreachScoreRule]

        init(rules: [any OutreachScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OutreachScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachScore]) -> [String: [String]] {
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

    static func defaultOutreachScoreValidator() -> OutreachScoreValidator {
        return OutreachScoreValidator(
            rules: [
                OutreachScoreFloorValueRangeRule(min: 3.2, max: 2328.9),
                OutreachScoreRequiredBedRule(message: "outreach score needs a value"),
                OutreachScoreDiscountRangeRule(min: 4.8, max: 1073.7),
            ]
        )
    }
}
