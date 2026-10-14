import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a tiered interaction draft must pass. Check returns its problems, or none.
    protocol TieredInteractionDraftRule {
        func check(_ item: TieredInteractionDraft) -> [String]
    }

    final class TieredInteractionDraftRequiredCodeRule: TieredInteractionDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredInteractionDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredInteractionDraftMinimumRangeRule: TieredInteractionDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredInteractionDraft) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredInteractionDraftTitleLengthRule: TieredInteractionDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredInteractionDraft) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredInteractionDraftPayerLengthRule: TieredInteractionDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredInteractionDraft) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredInteractionDraftCreatedAtRangeRule: TieredInteractionDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredInteractionDraft) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredInteractionDraftCodePrefixRule: TieredInteractionDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredInteractionDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered interaction draft.
    final class TieredInteractionDraftValidator {
        var rules: [any TieredInteractionDraftRule]

        init(rules: [any TieredInteractionDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredInteractionDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredInteractionDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredInteractionDraft]) -> [String: [String]] {
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

    static func defaultTieredInteractionDraftValidator() -> TieredInteractionDraftValidator {
        return TieredInteractionDraftValidator(
            rules: [
                TieredInteractionDraftRequiredCodeRule(message: "tiered interaction draft needs an entry"),
                TieredInteractionDraftMinimumRangeRule(min: 9.2, max: 1882.3),
                TieredInteractionDraftTitleLengthRule(maxLength: 80),
                TieredInteractionDraftPayerLengthRule(maxLength: 86400),
                TieredInteractionDraftCreatedAtRangeRule(min: 120, max: 1000),
                TieredInteractionDraftCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
