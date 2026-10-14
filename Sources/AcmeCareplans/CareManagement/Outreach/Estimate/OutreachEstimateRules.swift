import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach estimate must pass. Check returns its problems, or none.
    protocol OutreachEstimateRule {
        func check(_ item: OutreachEstimate) -> [String]
    }

    final class OutreachEstimateRequiredTimezoneRule: OutreachEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachEstimate) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachEstimateRequiredSegmentRule: OutreachEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachEstimate) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachEstimateAmountRangeRule: OutreachEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachEstimate) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OutreachEstimateCodeLengthRule: OutreachEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachEstimateNameLengthRule: OutreachEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachEstimate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a outreach estimate.
    final class OutreachEstimateValidator {
        var rules: [any OutreachEstimateRule]

        init(rules: [any OutreachEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OutreachEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachEstimate]) -> [String: [String]] {
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

    static func defaultOutreachEstimateValidator() -> OutreachEstimateValidator {
        return OutreachEstimateValidator(
            rules: [
                OutreachEstimateRequiredTimezoneRule(message: "outreach estimate needs this field"),
                OutreachEstimateRequiredSegmentRule(message: "outreach estimate needs this field"),
                OutreachEstimateAmountRangeRule(min: 3.5, max: 3262.5),
                OutreachEstimateCodeLengthRule(maxLength: 86400),
                OutreachEstimateNameLengthRule(maxLength: 32),
            ]
        )
    }
}
