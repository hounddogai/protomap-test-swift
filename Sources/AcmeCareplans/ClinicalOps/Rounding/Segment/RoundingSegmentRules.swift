import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding segment must pass. Check returns its problems, or none.
    protocol RoundingSegmentRule {
        func check(_ item: RoundingSegment) -> [String]
    }

    final class RoundingSegmentLimitRangeRule: RoundingSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingSegment) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RoundingSegmentRequiredNameRule: RoundingSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingSegment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingSegmentCodeLengthRule: RoundingSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingSegmentRequiredExternalRefRule: RoundingSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingSegment) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingSegmentVisitMinutesRangeRule: RoundingSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingSegment) -> [String] {
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

    final class RoundingSegmentProcedureCodeLengthRule: RoundingSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingSegment) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rounding segment.
    final class RoundingSegmentValidator {
        var rules: [any RoundingSegmentRule]

        init(rules: [any RoundingSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RoundingSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingSegment]) -> [String: [String]] {
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

    static func defaultRoundingSegmentValidator() -> RoundingSegmentValidator {
        return RoundingSegmentValidator(
            rules: [
                RoundingSegmentLimitRangeRule(min: 3600, max: 3600),
                RoundingSegmentRequiredNameRule(message: "rounding segment needs an entry"),
                RoundingSegmentCodeLengthRule(maxLength: 32),
                RoundingSegmentRequiredExternalRefRule(message: "rounding segment needs this field"),
                RoundingSegmentVisitMinutesRangeRule(min: 120, max: 1000),
                RoundingSegmentProcedureCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
