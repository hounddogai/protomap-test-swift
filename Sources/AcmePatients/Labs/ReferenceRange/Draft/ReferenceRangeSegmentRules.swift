import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range segment must pass. Check returns its problems, or none.
    protocol ReferenceRangeSegmentRule {
        func check(_ item: ReferenceRangeSegment) -> [String]
    }

    final class ReferenceRangeSegmentSegmentLengthRule: ReferenceRangeSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeSegment) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeSegmentRequiredNameRule: ReferenceRangeSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeSegment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeSegmentSpecialtyLengthRule: ReferenceRangeSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeSegment) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeSegmentAcuityRangeRule: ReferenceRangeSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeSegment) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a reference range segment.
    final class ReferenceRangeSegmentValidator {
        var rules: [any ReferenceRangeSegmentRule]

        init(rules: [any ReferenceRangeSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeSegment) -> [String] {
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

        func requireValid(_ item: ReferenceRangeSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeSegment]) -> [String: [String]] {
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

    static func defaultReferenceRangeSegmentValidator() -> ReferenceRangeSegmentValidator {
        return ReferenceRangeSegmentValidator(
            rules: [
                ReferenceRangeSegmentSegmentLengthRule(maxLength: 120),
                ReferenceRangeSegmentRequiredNameRule(message: "reference range segment needs this field"),
                ReferenceRangeSegmentSpecialtyLengthRule(maxLength: 120),
                ReferenceRangeSegmentAcuityRangeRule(min: 16, max: 120),
            ]
        )
    }
}
