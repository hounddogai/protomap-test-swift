import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a global slot estimate must pass. Check returns its problems, or none.
    protocol GlobalSlotEstimateRule {
        func check(_ item: GlobalSlotEstimate) -> [String]
    }

    final class GlobalSlotEstimateChannelLengthRule: GlobalSlotEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalSlotEstimate) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalSlotEstimateAcuityRangeRule: GlobalSlotEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalSlotEstimate) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalSlotEstimateRequiredTitleRule: GlobalSlotEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalSlotEstimate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalSlotEstimateTitleLengthRule: GlobalSlotEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalSlotEstimate) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalSlotEstimateRequiredAllergyRule: GlobalSlotEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalSlotEstimate) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalSlotEstimateMarginRangeRule: GlobalSlotEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalSlotEstimate) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a global slot estimate.
    final class GlobalSlotEstimateValidator {
        var rules: [any GlobalSlotEstimateRule]

        init(rules: [any GlobalSlotEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalSlotEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalSlotEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalSlotEstimate]) -> [String: [String]] {
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

    static func defaultGlobalSlotEstimateValidator() -> GlobalSlotEstimateValidator {
        return GlobalSlotEstimateValidator(
            rules: [
                GlobalSlotEstimateChannelLengthRule(maxLength: 16),
                GlobalSlotEstimateAcuityRangeRule(min: 64, max: 255),
                GlobalSlotEstimateRequiredTitleRule(message: "global slot estimate needs a value"),
                GlobalSlotEstimateTitleLengthRule(maxLength: 1000),
                GlobalSlotEstimateRequiredAllergyRule(message: "global slot estimate needs an entry"),
                GlobalSlotEstimateMarginRangeRule(min: 8.9, max: 351.8),
            ]
        )
    }
}
