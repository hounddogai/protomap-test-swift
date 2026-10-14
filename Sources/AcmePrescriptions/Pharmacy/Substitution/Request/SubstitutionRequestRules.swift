import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution request must pass. Check returns its problems, or none.
    protocol SubstitutionRequestRule {
        func check(_ item: SubstitutionRequest) -> [String]
    }

    final class SubstitutionRequestDurationMinutesRangeRule: SubstitutionRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionRequest) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SubstitutionRequestQuantityRangeRule: SubstitutionRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionRequest) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SubstitutionRequestTagsLimitRule: SubstitutionRequestRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: SubstitutionRequest) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class SubstitutionRequestRequiredTitleRule: SubstitutionRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionRequest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a substitution request.
    final class SubstitutionRequestValidator {
        var rules: [any SubstitutionRequestRule]

        init(rules: [any SubstitutionRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionRequest) -> [String] {
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

        func requireValid(_ item: SubstitutionRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionRequest]) -> [String: [String]] {
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

    static func defaultSubstitutionRequestValidator() -> SubstitutionRequestValidator {
        return SubstitutionRequestValidator(
            rules: [
                SubstitutionRequestDurationMinutesRangeRule(min: 32, max: 255),
                SubstitutionRequestQuantityRangeRule(min: 3600, max: 86400),
                SubstitutionRequestTagsLimitRule(maxCount: 86400, banned: []),
                SubstitutionRequestRequiredTitleRule(message: "substitution request needs an entry"),
            ]
        )
    }
}
