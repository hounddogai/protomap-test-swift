import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen estimate must pass. Check returns its problems, or none.
    protocol SpecimenEstimateRule {
        func check(_ item: SpecimenEstimate) -> [String]
    }

    final class SpecimenEstimateSegmentLengthRule: SpecimenEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenEstimate) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenEstimateRequiredNameRule: SpecimenEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenEstimate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenEstimateSequenceRangeRule: SpecimenEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenEstimate) -> [String] {
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

    /// Runs every rule of a specimen estimate.
    final class SpecimenEstimateValidator {
        var rules: [any SpecimenEstimateRule]

        init(rules: [any SpecimenEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenEstimate) -> [String] {
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

        func requireValid(_ item: SpecimenEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenEstimate]) -> [String: [String]] {
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

    static func defaultSpecimenEstimateValidator() -> SpecimenEstimateValidator {
        return SpecimenEstimateValidator(
            rules: [
                SpecimenEstimateSegmentLengthRule(maxLength: 1000),
                SpecimenEstimateRequiredNameRule(message: "specimen estimate needs a value"),
                SpecimenEstimateSequenceRangeRule(min: 64, max: 86400),
            ]
        )
    }
}
