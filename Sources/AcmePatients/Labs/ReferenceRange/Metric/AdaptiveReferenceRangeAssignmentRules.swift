import AcmePlatform
import Foundation

extension Labs {
    /// A rule a adaptive reference range assignment must pass. Check returns its problems, or none.
    protocol AdaptiveReferenceRangeAssignmentRule {
        func check(_ item: AdaptiveReferenceRangeAssignment) -> [String]
    }

    final class AdaptiveReferenceRangeAssignmentNameLengthRule: AdaptiveReferenceRangeAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveReferenceRangeAssignment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveReferenceRangeAssignmentRequiredFacilityRule: AdaptiveReferenceRangeAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveReferenceRangeAssignment) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveReferenceRangeAssignmentRequiredCodeRule: AdaptiveReferenceRangeAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveReferenceRangeAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveReferenceRangeAssignmentCodeLengthRule: AdaptiveReferenceRangeAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveReferenceRangeAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveReferenceRangeAssignmentQuantityRangeRule: AdaptiveReferenceRangeAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveReferenceRangeAssignment) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a adaptive reference range assignment.
    final class AdaptiveReferenceRangeAssignmentValidator {
        var rules: [any AdaptiveReferenceRangeAssignmentRule]

        init(rules: [any AdaptiveReferenceRangeAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveReferenceRangeAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveReferenceRangeAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveReferenceRangeAssignment]) -> [String: [String]] {
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

    static func defaultAdaptiveReferenceRangeAssignmentValidator() -> AdaptiveReferenceRangeAssignmentValidator {
        return AdaptiveReferenceRangeAssignmentValidator(
            rules: [
                AdaptiveReferenceRangeAssignmentNameLengthRule(maxLength: 32),
                AdaptiveReferenceRangeAssignmentRequiredFacilityRule(
                    message: "adaptive reference range assignment needs a value"
                ),
                AdaptiveReferenceRangeAssignmentRequiredCodeRule(
                    message: "adaptive reference range assignment needs this field"
                ),
                AdaptiveReferenceRangeAssignmentCodeLengthRule(maxLength: 32),
                AdaptiveReferenceRangeAssignmentQuantityRangeRule(min: 16, max: 16),
            ]
        )
    }
}
