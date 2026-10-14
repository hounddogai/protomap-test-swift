import AcmePlatform
import Foundation

extension Labs {
    /// A rule a default accession window must pass. Check returns its problems, or none.
    protocol DefaultAccessionWindowRule {
        func check(_ item: DefaultAccessionWindow) -> [String]
    }

    final class DefaultAccessionWindowEncounterIDLengthRule: DefaultAccessionWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultAccessionWindow) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultAccessionWindowRequiredCodeRule: DefaultAccessionWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultAccessionWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultAccessionWindowTagsLimitRule: DefaultAccessionWindowRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: DefaultAccessionWindow) -> [String] {
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

    final class DefaultAccessionWindowActiveGuardRule: DefaultAccessionWindowRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: DefaultAccessionWindow) -> [String] {
            if item.active && (item.margin > limit) {
                return ["margin \(item.margin) exceeds \(limit) while active"]
            }
            return []
        }
    }

    /// Runs every rule of a default accession window.
    final class DefaultAccessionWindowValidator {
        var rules: [any DefaultAccessionWindowRule]

        init(rules: [any DefaultAccessionWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultAccessionWindow) -> [String] {
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

        func requireValid(_ item: DefaultAccessionWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultAccessionWindow]) -> [String: [String]] {
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

    static func defaultDefaultAccessionWindowValidator() -> DefaultAccessionWindowValidator {
        return DefaultAccessionWindowValidator(
            rules: [
                DefaultAccessionWindowEncounterIDLengthRule(maxLength: 120),
                DefaultAccessionWindowRequiredCodeRule(message: "default accession window needs this field"),
                DefaultAccessionWindowTagsLimitRule(maxCount: 1000, banned: ["adaptive", "adaptive"]),
                DefaultAccessionWindowActiveGuardRule(limit: 1.9),
            ]
        )
    }
}
