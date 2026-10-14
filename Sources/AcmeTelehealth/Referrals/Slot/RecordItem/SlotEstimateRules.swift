import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot estimate must pass. Check returns its problems, or none.
    protocol SlotEstimateRule {
        func check(_ item: SlotEstimate) -> [String]
    }

    final class SlotEstimateCodeLengthRule: SlotEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotEstimateRequiredCodeRule: SlotEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotEstimateRequiredReviewerRule: SlotEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotEstimate) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a slot estimate.
    final class SlotEstimateValidator {
        var rules: [any SlotEstimateRule]

        init(rules: [any SlotEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SlotEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotEstimate]) -> [String: [String]] {
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

    static func defaultSlotEstimateValidator() -> SlotEstimateValidator {
        return SlotEstimateValidator(
            rules: [
                SlotEstimateCodeLengthRule(maxLength: 1000),
                SlotEstimateRequiredCodeRule(message: "slot estimate needs this field"),
                SlotEstimateRequiredReviewerRule(message: "slot estimate needs a value"),
            ]
        )
    }
}
