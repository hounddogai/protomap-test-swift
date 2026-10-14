import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a lenient modality score must pass. Check returns its problems, or none.
    protocol LenientModalityScoreRule {
        func check(_ item: LenientModalityScore) -> [String]
    }

    final class LenientModalityScoreCodeLengthRule: LenientModalityScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientModalityScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientModalityScorePriorityRangeRule: LenientModalityScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientModalityScore) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientModalityScoreLimitRangeRule: LenientModalityScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientModalityScore) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientModalityScoreAllowedTitleRule: LenientModalityScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientModalityScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is expired"]
            }
            return []
        }
    }

    final class LenientModalityScorePinnedGuardRule: LenientModalityScoreRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: LenientModalityScore) -> [String] {
            if item.pinned && (item.priority > limit) {
                return ["priority \(item.priority) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class LenientModalityScoreRequiredPatientRefRule: LenientModalityScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientModalityScore) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient modality score.
    final class LenientModalityScoreValidator {
        var rules: [any LenientModalityScoreRule]

        init(rules: [any LenientModalityScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientModalityScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientModalityScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientModalityScore]) -> [String: [String]] {
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

    static func defaultLenientModalityScoreValidator() -> LenientModalityScoreValidator {
        return LenientModalityScoreValidator(
            rules: [
                LenientModalityScoreCodeLengthRule(maxLength: 16),
                LenientModalityScorePriorityRangeRule(min: 80, max: 255),
                LenientModalityScoreLimitRangeRule(min: 1000, max: 3600),
                LenientModalityScoreAllowedTitleRule(allowed: ["seasonal"]),
                LenientModalityScorePinnedGuardRule(limit: 1000),
                LenientModalityScoreRequiredPatientRefRule(message: "lenient modality score needs this field"),
            ]
        )
    }
}
