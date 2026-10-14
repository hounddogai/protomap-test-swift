import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness draft must pass. Check returns its problems, or none.
    protocol WitnessDraftRule {
        func check(_ item: WitnessDraft) -> [String]
    }

    final class WitnessDraftSummaryLengthRule: WitnessDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessDraft) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessDraftRequiredLabelRule: WitnessDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessDraft) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessDraftScoreRangeRule: WitnessDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessDraft) -> [String] {
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

    final class WitnessDraftArchivedGuardRule: WitnessDraftRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: WitnessDraft) -> [String] {
            if item.archived && (item.rate > limit) {
                return ["rate \(item.rate) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class WitnessDraftWardLengthRule: WitnessDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessDraft) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a witness draft.
    final class WitnessDraftValidator {
        var rules: [any WitnessDraftRule]

        init(rules: [any WitnessDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessDraft) -> [String] {
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

        func requireValid(_ item: WitnessDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessDraft]) -> [String: [String]] {
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

    static func defaultWitnessDraftValidator() -> WitnessDraftValidator {
        return WitnessDraftValidator(
            rules: [
                WitnessDraftSummaryLengthRule(maxLength: 3600),
                WitnessDraftRequiredLabelRule(message: "witness draft needs a value"),
                WitnessDraftScoreRangeRule(min: 2.6, max: 3272.9),
                WitnessDraftArchivedGuardRule(limit: 7.6),
                WitnessDraftWardLengthRule(maxLength: 86400),
            ]
        )
    }
}
