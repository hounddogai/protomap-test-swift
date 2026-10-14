import AcmePlatform
import Foundation

extension Labs {
    /// A rule a pending reference range score must pass. Check returns its problems, or none.
    protocol PendingReferenceRangeScoreRule {
        func check(_ item: PendingReferenceRangeScore) -> [String]
    }

    final class PendingReferenceRangeScoreCodePrefixRule: PendingReferenceRangeScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingReferenceRangeScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingReferenceRangeScoreCodeLengthRule: PendingReferenceRangeScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingReferenceRangeScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingReferenceRangeScoreRequiredCurrencyRule: PendingReferenceRangeScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingReferenceRangeScore) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingReferenceRangeScoreTitleLengthRule: PendingReferenceRangeScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingReferenceRangeScore) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingReferenceRangeScoreCeilingRangeRule: PendingReferenceRangeScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingReferenceRangeScore) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending reference range score.
    final class PendingReferenceRangeScoreValidator {
        var rules: [any PendingReferenceRangeScoreRule]

        init(rules: [any PendingReferenceRangeScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingReferenceRangeScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingReferenceRangeScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingReferenceRangeScore]) -> [String: [String]] {
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

    static func defaultPendingReferenceRangeScoreValidator() -> PendingReferenceRangeScoreValidator {
        return PendingReferenceRangeScoreValidator(
            rules: [
                PendingReferenceRangeScoreCodePrefixRule(prefix: "OPS"),
                PendingReferenceRangeScoreCodeLengthRule(maxLength: 120),
                PendingReferenceRangeScoreRequiredCurrencyRule(
                    message: "pending reference range score needs this field"
                ),
                PendingReferenceRangeScoreTitleLengthRule(maxLength: 1000),
                PendingReferenceRangeScoreCeilingRangeRule(min: 9.8, max: 4189.4),
            ]
        )
    }
}
