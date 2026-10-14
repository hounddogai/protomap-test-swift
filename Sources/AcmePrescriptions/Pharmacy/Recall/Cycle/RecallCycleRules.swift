import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall cycle must pass. Check returns its problems, or none.
    protocol RecallCycleRule {
        func check(_ item: RecallCycle) -> [String]
    }

    final class RecallCycleRequiredCodeRule: RecallCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallCycleTitleLengthRule: RecallCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallCycle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallCycleRevisionRangeRule: RecallCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallCycle) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RecallCyclePinnedGuardRule: RecallCycleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RecallCycle) -> [String] {
            if item.pinned && (item.revision > limit) {
                return ["revision \(item.revision) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class RecallCycleRequiredSegmentRule: RecallCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallCycle) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallCycleRequiredNameRule: RecallCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallCycle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a recall cycle.
    final class RecallCycleValidator {
        var rules: [any RecallCycleRule]

        init(rules: [any RecallCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallCycle) -> [String] {
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

        func requireValid(_ item: RecallCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallCycle]) -> [String: [String]] {
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

    static func defaultRecallCycleValidator() -> RecallCycleValidator {
        return RecallCycleValidator(
            rules: [
                RecallCycleRequiredCodeRule(message: "recall cycle needs an entry"),
                RecallCycleTitleLengthRule(maxLength: 80),
                RecallCycleRevisionRangeRule(min: 16, max: 32),
                RecallCyclePinnedGuardRule(limit: 86400),
                RecallCycleRequiredSegmentRule(message: "recall cycle needs this field"),
                RecallCycleRequiredNameRule(message: "recall cycle needs a value"),
            ]
        )
    }
}
