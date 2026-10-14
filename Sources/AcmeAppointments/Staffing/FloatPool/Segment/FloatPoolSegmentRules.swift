import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool segment must pass. Check returns its problems, or none.
    protocol FloatPoolSegmentRule {
        func check(_ item: FloatPoolSegment) -> [String]
    }

    final class FloatPoolSegmentEncounterIDLengthRule: FloatPoolSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolSegment) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolSegmentExpiresAtRangeRule: FloatPoolSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolSegment) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FloatPoolSegmentCodeLengthRule: FloatPoolSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolSegmentPriorityRangeRule: FloatPoolSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolSegment) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a float pool segment.
    final class FloatPoolSegmentValidator {
        var rules: [any FloatPoolSegmentRule]

        init(rules: [any FloatPoolSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FloatPoolSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolSegment]) -> [String: [String]] {
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

    static func defaultFloatPoolSegmentValidator() -> FloatPoolSegmentValidator {
        return FloatPoolSegmentValidator(
            rules: [
                FloatPoolSegmentEncounterIDLengthRule(maxLength: 120),
                FloatPoolSegmentExpiresAtRangeRule(min: 1000, max: 3600),
                FloatPoolSegmentCodeLengthRule(maxLength: 3600),
                FloatPoolSegmentPriorityRangeRule(min: 64, max: 80),
            ]
        )
    }
}
