import AcmePlatform
import Foundation

extension Labs {
    /// A rule a tiered specimen assignment must pass. Check returns its problems, or none.
    protocol TieredSpecimenAssignmentRule {
        func check(_ item: TieredSpecimenAssignment) -> [String]
    }

    final class TieredSpecimenAssignmentCodeLengthRule: TieredSpecimenAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredSpecimenAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredSpecimenAssignmentPhoneLengthRule: TieredSpecimenAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredSpecimenAssignment) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredSpecimenAssignmentFacilityLengthRule: TieredSpecimenAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredSpecimenAssignment) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredSpecimenAssignmentRequiredFacilityRule: TieredSpecimenAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredSpecimenAssignment) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredSpecimenAssignmentMarginRangeRule: TieredSpecimenAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredSpecimenAssignment) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a tiered specimen assignment.
    final class TieredSpecimenAssignmentValidator {
        var rules: [any TieredSpecimenAssignmentRule]

        init(rules: [any TieredSpecimenAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredSpecimenAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredSpecimenAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredSpecimenAssignment]) -> [String: [String]] {
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

    static func defaultTieredSpecimenAssignmentValidator() -> TieredSpecimenAssignmentValidator {
        return TieredSpecimenAssignmentValidator(
            rules: [
                TieredSpecimenAssignmentCodeLengthRule(maxLength: 80),
                TieredSpecimenAssignmentPhoneLengthRule(maxLength: 3600),
                TieredSpecimenAssignmentFacilityLengthRule(maxLength: 3600),
                TieredSpecimenAssignmentRequiredFacilityRule(message: "tiered specimen assignment needs a value"),
                TieredSpecimenAssignmentMarginRangeRule(min: 4.5, max: 3997.0),
            ]
        )
    }
}
