import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a lenient formulary draft must pass. Check returns its problems, or none.
    protocol LenientFormularyDraftRule {
        func check(_ item: LenientFormularyDraft) -> [String]
    }

    final class LenientFormularyDraftCodeLengthRule: LenientFormularyDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientFormularyDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientFormularyDraftRateRangeRule: LenientFormularyDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientFormularyDraft) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientFormularyDraftTagsLimitRule: LenientFormularyDraftRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: LenientFormularyDraft) -> [String] {
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

    /// Runs every rule of a lenient formulary draft.
    final class LenientFormularyDraftValidator {
        var rules: [any LenientFormularyDraftRule]

        init(rules: [any LenientFormularyDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientFormularyDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientFormularyDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientFormularyDraft]) -> [String: [String]] {
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

    static func defaultLenientFormularyDraftValidator() -> LenientFormularyDraftValidator {
        return LenientFormularyDraftValidator(
            rules: [
                LenientFormularyDraftCodeLengthRule(maxLength: 64),
                LenientFormularyDraftRateRangeRule(min: 2.5, max: 1166.2),
                LenientFormularyDraftTagsLimitRule(maxCount: 32, banned: ["regional", "seasonal", "primary"]),
            ]
        )
    }
}
