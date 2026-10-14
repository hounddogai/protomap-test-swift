import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a regional modality claim must pass. Check returns its problems, or none.
    protocol RegionalModalityClaimRule {
        func check(_ item: RegionalModalityClaim) -> [String]
    }

    final class RegionalModalityClaimChannelLengthRule: RegionalModalityClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalModalityClaim) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalModalityClaimCapacityRangeRule: RegionalModalityClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalModalityClaim) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalModalityClaimRequiredLabelRule: RegionalModalityClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalModalityClaim) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalModalityClaimRequiredSummaryRule: RegionalModalityClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalModalityClaim) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional modality claim.
    final class RegionalModalityClaimValidator {
        var rules: [any RegionalModalityClaimRule]

        init(rules: [any RegionalModalityClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalModalityClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalModalityClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalModalityClaim]) -> [String: [String]] {
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

    static func defaultRegionalModalityClaimValidator() -> RegionalModalityClaimValidator {
        return RegionalModalityClaimValidator(
            rules: [
                RegionalModalityClaimChannelLengthRule(maxLength: 80),
                RegionalModalityClaimCapacityRangeRule(min: 80, max: 255),
                RegionalModalityClaimRequiredLabelRule(message: "regional modality claim needs an entry"),
                RegionalModalityClaimRequiredSummaryRule(message: "regional modality claim needs this field"),
            ]
        )
    }
}
