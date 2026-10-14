import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement segment must pass. Check returns its problems, or none.
    protocol StatementSegmentRule {
        func check(_ item: StatementSegment) -> [String]
    }

    final class StatementSegmentEncounterIDLengthRule: StatementSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementSegment) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementSegmentAllowedEncounterIDRule: StatementSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StatementSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.encounterID)) {
                return ["encounter id \(item.encounterID) is duplicated"]
            }
            return []
        }
    }

    final class StatementSegmentMinimumRangeRule: StatementSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementSegment) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a statement segment.
    final class StatementSegmentValidator {
        var rules: [any StatementSegmentRule]

        init(rules: [any StatementSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StatementSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementSegment]) -> [String: [String]] {
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

    static func defaultStatementSegmentValidator() -> StatementSegmentValidator {
        return StatementSegmentValidator(
            rules: [
                StatementSegmentEncounterIDLengthRule(maxLength: 1000),
                StatementSegmentAllowedEncounterIDRule(allowed: ["manual", "strict", "fallback"]),
                StatementSegmentMinimumRangeRule(min: 1.2, max: 2391.1),
            ]
        )
    }
}
