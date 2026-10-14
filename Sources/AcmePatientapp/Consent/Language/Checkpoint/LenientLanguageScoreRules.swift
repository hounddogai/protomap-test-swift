import AcmePlatform
import Foundation

extension Consent {
    /// A rule a lenient language score must pass. Check returns its problems, or none.
    protocol LenientLanguageScoreRule {
        func check(_ item: LenientLanguageScore) -> [String]
    }

    final class LenientLanguageScorePinnedGuardRule: LenientLanguageScoreRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: LenientLanguageScore) -> [String] {
            if item.pinned && (item.retries > limit) {
                return ["retries \(item.retries) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class LenientLanguageScoreRequiredCodeRule: LenientLanguageScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientLanguageScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientLanguageScoreRetriesRangeRule: LenientLanguageScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientLanguageScore) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientLanguageScoreCodeLengthRule: LenientLanguageScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientLanguageScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientLanguageScoreNameLengthRule: LenientLanguageScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientLanguageScore) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientLanguageScoreStartsAtRangeRule: LenientLanguageScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientLanguageScore) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient language score.
    final class LenientLanguageScoreValidator {
        var rules: [any LenientLanguageScoreRule]

        init(rules: [any LenientLanguageScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientLanguageScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientLanguageScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientLanguageScore]) -> [String: [String]] {
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

    static func defaultLenientLanguageScoreValidator() -> LenientLanguageScoreValidator {
        return LenientLanguageScoreValidator(
            rules: [
                LenientLanguageScorePinnedGuardRule(limit: 80),
                LenientLanguageScoreRequiredCodeRule(message: "lenient language score needs an entry"),
                LenientLanguageScoreRetriesRangeRule(min: 16, max: 86400),
                LenientLanguageScoreCodeLengthRule(maxLength: 16),
                LenientLanguageScoreNameLengthRule(maxLength: 80),
                LenientLanguageScoreStartsAtRangeRule(min: 32, max: 64),
            ]
        )
    }
}
