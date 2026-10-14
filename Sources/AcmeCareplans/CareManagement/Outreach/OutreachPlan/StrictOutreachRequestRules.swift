import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a strict outreach request must pass. Check returns its problems, or none.
    protocol StrictOutreachRequestRule {
        func check(_ item: StrictOutreachRequest) -> [String]
    }

    final class StrictOutreachRequestDiscountRangeRule: StrictOutreachRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictOutreachRequest) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictOutreachRequestRatioRangeRule: StrictOutreachRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictOutreachRequest) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictOutreachRequestPatientRefLengthRule: StrictOutreachRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictOutreachRequest) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictOutreachRequestRequiredNameRule: StrictOutreachRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictOutreachRequest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict outreach request.
    final class StrictOutreachRequestValidator {
        var rules: [any StrictOutreachRequestRule]

        init(rules: [any StrictOutreachRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictOutreachRequest) -> [String] {
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

        func requireValid(_ item: StrictOutreachRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictOutreachRequest]) -> [String: [String]] {
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

    static func defaultStrictOutreachRequestValidator() -> StrictOutreachRequestValidator {
        return StrictOutreachRequestValidator(
            rules: [
                StrictOutreachRequestDiscountRangeRule(min: 8.8, max: 2556.8),
                StrictOutreachRequestRatioRangeRule(min: 7.8, max: 3622.7),
                StrictOutreachRequestPatientRefLengthRule(maxLength: 255),
                StrictOutreachRequestRequiredNameRule(message: "strict outreach request needs an entry"),
            ]
        )
    }
}
