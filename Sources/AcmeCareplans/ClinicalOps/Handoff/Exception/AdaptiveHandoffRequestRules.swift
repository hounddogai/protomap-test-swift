import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a adaptive handoff request must pass. Check returns its problems, or none.
    protocol AdaptiveHandoffRequestRule {
        func check(_ item: AdaptiveHandoffRequest) -> [String]
    }

    final class AdaptiveHandoffRequestCodeLengthRule: AdaptiveHandoffRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveHandoffRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveHandoffRequestDosageMgRangeRule: AdaptiveHandoffRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveHandoffRequest) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveHandoffRequestRequiredChannelRule: AdaptiveHandoffRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveHandoffRequest) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveHandoffRequestBudgetRangeRule: AdaptiveHandoffRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveHandoffRequest) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveHandoffRequestRequiredLabelRule: AdaptiveHandoffRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveHandoffRequest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveHandoffRequestPinnedGuardRule: AdaptiveHandoffRequestRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: AdaptiveHandoffRequest) -> [String] {
            if item.pinned && (item.budget > limit) {
                return ["budget \(item.budget) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive handoff request.
    final class AdaptiveHandoffRequestValidator {
        var rules: [any AdaptiveHandoffRequestRule]

        init(rules: [any AdaptiveHandoffRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveHandoffRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveHandoffRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveHandoffRequest]) -> [String: [String]] {
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

    static func defaultAdaptiveHandoffRequestValidator() -> AdaptiveHandoffRequestValidator {
        return AdaptiveHandoffRequestValidator(
            rules: [
                AdaptiveHandoffRequestCodeLengthRule(maxLength: 3600),
                AdaptiveHandoffRequestDosageMgRangeRule(min: 1.2, max: 4315.6),
                AdaptiveHandoffRequestRequiredChannelRule(message: "adaptive handoff request needs a value"),
                AdaptiveHandoffRequestBudgetRangeRule(min: 9.2, max: 121.7),
                AdaptiveHandoffRequestRequiredLabelRule(message: "adaptive handoff request needs an entry"),
                AdaptiveHandoffRequestPinnedGuardRule(limit: 9.2),
            ]
        )
    }
}
