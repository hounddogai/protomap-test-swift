import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range baseline must pass. Check returns its problems, or none.
    protocol ReferenceRangeBaselineRule {
        func check(_ item: ReferenceRangeBaseline) -> [String]
    }

    final class ReferenceRangeBaselineRequiredCountryRule: ReferenceRangeBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeBaseline) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeBaselineScoreRangeRule: ReferenceRangeBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeBaseline) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReferenceRangeBaselineNameLengthRule: ReferenceRangeBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeBaseline) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeBaselineRequiredClinicianIDRule: ReferenceRangeBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeBaseline) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a reference range baseline.
    final class ReferenceRangeBaselineValidator {
        var rules: [any ReferenceRangeBaselineRule]

        init(rules: [any ReferenceRangeBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeBaseline) -> [String] {
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

        func requireValid(_ item: ReferenceRangeBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeBaseline]) -> [String: [String]] {
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

    static func defaultReferenceRangeBaselineValidator() -> ReferenceRangeBaselineValidator {
        return ReferenceRangeBaselineValidator(
            rules: [
                ReferenceRangeBaselineRequiredCountryRule(message: "reference range baseline needs an entry"),
                ReferenceRangeBaselineScoreRangeRule(min: 0.6, max: 4643.5),
                ReferenceRangeBaselineNameLengthRule(maxLength: 3600),
                ReferenceRangeBaselineRequiredClinicianIDRule(message: "reference range baseline needs an entry"),
            ]
        )
    }
}
