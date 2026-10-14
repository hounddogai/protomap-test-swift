import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a fallback inventory score must pass. Check returns its problems, or none.
    protocol FallbackInventoryScoreRule {
        func check(_ item: FallbackInventoryScore) -> [String]
    }

    final class FallbackInventoryScoreCodeLengthRule: FallbackInventoryScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackInventoryScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackInventoryScoreNameLengthRule: FallbackInventoryScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackInventoryScore) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackInventoryScoreVisitMinutesRangeRule: FallbackInventoryScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackInventoryScore) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackInventoryScoreRequiredNameRule: FallbackInventoryScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackInventoryScore) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackInventoryScoreRequiredNotesRule: FallbackInventoryScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackInventoryScore) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackInventoryScoreAllowedCodeRule: FallbackInventoryScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackInventoryScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback inventory score.
    final class FallbackInventoryScoreValidator {
        var rules: [any FallbackInventoryScoreRule]

        init(rules: [any FallbackInventoryScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackInventoryScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackInventoryScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackInventoryScore]) -> [String: [String]] {
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

    static func defaultFallbackInventoryScoreValidator() -> FallbackInventoryScoreValidator {
        return FallbackInventoryScoreValidator(
            rules: [
                FallbackInventoryScoreCodeLengthRule(maxLength: 64),
                FallbackInventoryScoreNameLengthRule(maxLength: 120),
                FallbackInventoryScoreVisitMinutesRangeRule(min: 32, max: 120),
                FallbackInventoryScoreRequiredNameRule(message: "fallback inventory score needs a value"),
                FallbackInventoryScoreRequiredNotesRule(message: "fallback inventory score needs this field"),
                FallbackInventoryScoreAllowedCodeRule(allowed: []),
            ]
        )
    }
}
