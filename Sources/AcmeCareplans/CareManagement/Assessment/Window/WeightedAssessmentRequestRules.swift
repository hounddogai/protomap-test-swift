import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a weighted assessment request must pass. Check returns its problems, or none.
    protocol WeightedAssessmentRequestRule {
        func check(_ item: WeightedAssessmentRequest) -> [String]
    }

    final class WeightedAssessmentRequestCodeLengthRule: WeightedAssessmentRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedAssessmentRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedAssessmentRequestNameLengthRule: WeightedAssessmentRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedAssessmentRequest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedAssessmentRequestRequiredNameRule: WeightedAssessmentRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedAssessmentRequest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedAssessmentRequestCapacityRangeRule: WeightedAssessmentRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedAssessmentRequest) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedAssessmentRequestTitleLengthRule: WeightedAssessmentRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedAssessmentRequest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted assessment request.
    final class WeightedAssessmentRequestValidator {
        var rules: [any WeightedAssessmentRequestRule]

        init(rules: [any WeightedAssessmentRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedAssessmentRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedAssessmentRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedAssessmentRequest]) -> [String: [String]] {
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

    static func defaultWeightedAssessmentRequestValidator() -> WeightedAssessmentRequestValidator {
        return WeightedAssessmentRequestValidator(
            rules: [
                WeightedAssessmentRequestCodeLengthRule(maxLength: 64),
                WeightedAssessmentRequestNameLengthRule(maxLength: 80),
                WeightedAssessmentRequestRequiredNameRule(message: "weighted assessment request needs a value"),
                WeightedAssessmentRequestCapacityRangeRule(min: 80, max: 255),
                WeightedAssessmentRequestTitleLengthRule(maxLength: 255),
            ]
        )
    }
}
