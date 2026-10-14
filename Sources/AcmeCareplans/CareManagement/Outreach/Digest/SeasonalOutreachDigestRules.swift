import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a seasonal outreach digest must pass. Check returns its problems, or none.
    protocol SeasonalOutreachDigestRule {
        func check(_ item: SeasonalOutreachDigest) -> [String]
    }

    final class SeasonalOutreachDigestCreatedAtRangeRule: SeasonalOutreachDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalOutreachDigest) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalOutreachDigestRequiredNameRule: SeasonalOutreachDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalOutreachDigest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalOutreachDigestRequiredLabelRule: SeasonalOutreachDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalOutreachDigest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalOutreachDigestNameLengthRule: SeasonalOutreachDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalOutreachDigest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal outreach digest.
    final class SeasonalOutreachDigestValidator {
        var rules: [any SeasonalOutreachDigestRule]

        init(rules: [any SeasonalOutreachDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalOutreachDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalOutreachDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalOutreachDigest]) -> [String: [String]] {
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

    static func defaultSeasonalOutreachDigestValidator() -> SeasonalOutreachDigestValidator {
        return SeasonalOutreachDigestValidator(
            rules: [
                SeasonalOutreachDigestCreatedAtRangeRule(min: 32, max: 64),
                SeasonalOutreachDigestRequiredNameRule(message: "seasonal outreach digest needs an entry"),
                SeasonalOutreachDigestRequiredLabelRule(message: "seasonal outreach digest needs an entry"),
                SeasonalOutreachDigestNameLengthRule(maxLength: 255),
            ]
        )
    }
}
