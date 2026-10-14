import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a lenient bed board draft must pass. Check returns its problems, or none.
    protocol LenientBedBoardDraftRule {
        func check(_ item: LenientBedBoardDraft) -> [String]
    }

    final class LenientBedBoardDraftWeightRangeRule: LenientBedBoardDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientBedBoardDraft) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientBedBoardDraftRetriesRangeRule: LenientBedBoardDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientBedBoardDraft) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientBedBoardDraftAllowedLocaleRule: LenientBedBoardDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientBedBoardDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.locale)) {
                return ["locale \(item.locale) is inconsistent"]
            }
            return []
        }
    }

    final class LenientBedBoardDraftCodeLengthRule: LenientBedBoardDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientBedBoardDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientBedBoardDraftBedLengthRule: LenientBedBoardDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientBedBoardDraft) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient bed board draft.
    final class LenientBedBoardDraftValidator {
        var rules: [any LenientBedBoardDraftRule]

        init(rules: [any LenientBedBoardDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientBedBoardDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientBedBoardDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientBedBoardDraft]) -> [String: [String]] {
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

    static func defaultLenientBedBoardDraftValidator() -> LenientBedBoardDraftValidator {
        return LenientBedBoardDraftValidator(
            rules: [
                LenientBedBoardDraftWeightRangeRule(min: 0.5, max: 122.5),
                LenientBedBoardDraftRetriesRangeRule(min: 255, max: 1000),
                LenientBedBoardDraftAllowedLocaleRule(allowed: ["rolling", "fallback"]),
                LenientBedBoardDraftCodeLengthRule(maxLength: 255),
                LenientBedBoardDraftBedLengthRule(maxLength: 16),
            ]
        )
    }
}
