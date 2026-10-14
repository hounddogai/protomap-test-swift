import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen segment must pass. Check returns its problems, or none.
    protocol SpecimenSegmentRule {
        func check(_ item: SpecimenSegment) -> [String]
    }

    final class SpecimenSegmentStartsAtRangeRule: SpecimenSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenSegment) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SpecimenSegmentRequiredCodeRule: SpecimenSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenSegmentCreatedAtRangeRule: SpecimenSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenSegment) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a specimen segment.
    final class SpecimenSegmentValidator {
        var rules: [any SpecimenSegmentRule]

        init(rules: [any SpecimenSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SpecimenSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenSegment]) -> [String: [String]] {
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

    static func defaultSpecimenSegmentValidator() -> SpecimenSegmentValidator {
        return SpecimenSegmentValidator(
            rules: [
                SpecimenSegmentStartsAtRangeRule(min: 1000, max: 3600),
                SpecimenSegmentRequiredCodeRule(message: "specimen segment needs an entry"),
                SpecimenSegmentCreatedAtRangeRule(min: 64, max: 64),
            ]
        )
    }
}
