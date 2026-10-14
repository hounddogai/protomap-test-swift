import AcmePlatform
import Foundation

extension Labs {
    /// A rule a default reference range segment must pass. Check returns its problems, or none.
    protocol DefaultReferenceRangeSegmentRule {
        func check(_ item: DefaultReferenceRangeSegment) -> [String]
    }

    final class DefaultReferenceRangeSegmentMinimumRangeRule: DefaultReferenceRangeSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultReferenceRangeSegment) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultReferenceRangeSegmentBatchSizeRangeRule: DefaultReferenceRangeSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultReferenceRangeSegment) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultReferenceRangeSegmentRequiredEncounterIDRule: DefaultReferenceRangeSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultReferenceRangeSegment) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultReferenceRangeSegmentAllowedEncounterIDRule: DefaultReferenceRangeSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultReferenceRangeSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.encounterID)) {
                return ["encounter id \(item.encounterID) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a default reference range segment.
    final class DefaultReferenceRangeSegmentValidator {
        var rules: [any DefaultReferenceRangeSegmentRule]

        init(rules: [any DefaultReferenceRangeSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultReferenceRangeSegment) -> [String] {
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

        func requireValid(_ item: DefaultReferenceRangeSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultReferenceRangeSegment]) -> [String: [String]] {
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

    static func defaultDefaultReferenceRangeSegmentValidator() -> DefaultReferenceRangeSegmentValidator {
        return DefaultReferenceRangeSegmentValidator(
            rules: [
                DefaultReferenceRangeSegmentMinimumRangeRule(min: 1.0, max: 286.6),
                DefaultReferenceRangeSegmentBatchSizeRangeRule(min: 120, max: 255),
                DefaultReferenceRangeSegmentRequiredEncounterIDRule(
                    message: "default reference range segment needs this field"
                ),
                DefaultReferenceRangeSegmentAllowedEncounterIDRule(allowed: ["legacy"]),
            ]
        )
    }
}
