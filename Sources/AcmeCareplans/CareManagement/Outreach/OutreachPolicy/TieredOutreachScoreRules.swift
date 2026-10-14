import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a tiered outreach score must pass. Check returns its problems, or none.
    protocol TieredOutreachScoreRule {
        func check(_ item: TieredOutreachScore) -> [String]
    }

    final class TieredOutreachScoreNameLengthRule: TieredOutreachScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredOutreachScore) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredOutreachScoreCodeLengthRule: TieredOutreachScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredOutreachScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredOutreachScoreRequiredLabelRule: TieredOutreachScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredOutreachScore) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredOutreachScoreVersionRangeRule: TieredOutreachScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredOutreachScore) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a tiered outreach score.
    final class TieredOutreachScoreValidator {
        var rules: [any TieredOutreachScoreRule]

        init(rules: [any TieredOutreachScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredOutreachScore) -> [String] {
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

        func requireValid(_ item: TieredOutreachScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredOutreachScore]) -> [String: [String]] {
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

    static func defaultTieredOutreachScoreValidator() -> TieredOutreachScoreValidator {
        return TieredOutreachScoreValidator(
            rules: [
                TieredOutreachScoreNameLengthRule(maxLength: 255),
                TieredOutreachScoreCodeLengthRule(maxLength: 86400),
                TieredOutreachScoreRequiredLabelRule(message: "tiered outreach score needs this field"),
                TieredOutreachScoreVersionRangeRule(min: 1000, max: 3600),
            ]
        )
    }
}
