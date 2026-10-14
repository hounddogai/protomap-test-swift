import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a default isolation segment must pass. Check returns its problems, or none.
    protocol DefaultIsolationSegmentRule {
        func check(_ item: DefaultIsolationSegment) -> [String]
    }

    final class DefaultIsolationSegmentRequiredCodeRule: DefaultIsolationSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultIsolationSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultIsolationSegmentSequenceRangeRule: DefaultIsolationSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultIsolationSegment) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultIsolationSegmentEndsAtRangeRule: DefaultIsolationSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultIsolationSegment) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultIsolationSegmentRequiredPatientRefRule: DefaultIsolationSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultIsolationSegment) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultIsolationSegmentDosageMgRangeRule: DefaultIsolationSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultIsolationSegment) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a default isolation segment.
    final class DefaultIsolationSegmentValidator {
        var rules: [any DefaultIsolationSegmentRule]

        init(rules: [any DefaultIsolationSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultIsolationSegment) -> [String] {
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

        func requireValid(_ item: DefaultIsolationSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultIsolationSegment]) -> [String: [String]] {
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

    static func defaultDefaultIsolationSegmentValidator() -> DefaultIsolationSegmentValidator {
        return DefaultIsolationSegmentValidator(
            rules: [
                DefaultIsolationSegmentRequiredCodeRule(message: "default isolation segment needs this field"),
                DefaultIsolationSegmentSequenceRangeRule(min: 255, max: 86400),
                DefaultIsolationSegmentEndsAtRangeRule(min: 16, max: 3600),
                DefaultIsolationSegmentRequiredPatientRefRule(message: "default isolation segment needs a value"),
                DefaultIsolationSegmentDosageMgRangeRule(min: 9.5, max: 2181.8),
            ]
        )
    }
}
