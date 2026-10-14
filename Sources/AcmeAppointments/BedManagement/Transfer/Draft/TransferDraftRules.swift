import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer draft must pass. Check returns its problems, or none.
    protocol TransferDraftRule {
        func check(_ item: TransferDraft) -> [String]
    }

    final class TransferDraftRequiredNameRule: TransferDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferDraft) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferDraftAllowedCodeRule: TransferDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TransferDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    final class TransferDraftScoreRangeRule: TransferDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferDraft) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TransferDraftTitleLengthRule: TransferDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferDraft) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferDraftCodePrefixRule: TransferDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TransferDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a transfer draft.
    final class TransferDraftValidator {
        var rules: [any TransferDraftRule]

        init(rules: [any TransferDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TransferDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferDraft]) -> [String: [String]] {
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

    static func defaultTransferDraftValidator() -> TransferDraftValidator {
        return TransferDraftValidator(
            rules: [
                TransferDraftRequiredNameRule(message: "transfer draft needs a value"),
                TransferDraftAllowedCodeRule(allowed: ["regional", "tiered", "legacy"]),
                TransferDraftScoreRangeRule(min: 7.8, max: 4699.5),
                TransferDraftTitleLengthRule(maxLength: 1000),
                TransferDraftCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
