import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a capped care gap assignment must pass. Check returns its problems, or none.
    protocol CappedCareGapAssignmentRule {
        func check(_ item: CappedCareGapAssignment) -> [String]
    }

    final class CappedCareGapAssignmentFloorValueRangeRule: CappedCareGapAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedCareGapAssignment) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedCareGapAssignmentRequiredCodeRule: CappedCareGapAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedCareGapAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedCareGapAssignmentAllowedSourceRule: CappedCareGapAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedCareGapAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.source)) {
                return ["source \(item.source) is inconsistent"]
            }
            return []
        }
    }

    final class CappedCareGapAssignmentSourceLengthRule: CappedCareGapAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedCareGapAssignment) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped care gap assignment.
    final class CappedCareGapAssignmentValidator {
        var rules: [any CappedCareGapAssignmentRule]

        init(rules: [any CappedCareGapAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedCareGapAssignment) -> [String] {
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

        func requireValid(_ item: CappedCareGapAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedCareGapAssignment]) -> [String: [String]] {
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

    static func defaultCappedCareGapAssignmentValidator() -> CappedCareGapAssignmentValidator {
        return CappedCareGapAssignmentValidator(
            rules: [
                CappedCareGapAssignmentFloorValueRangeRule(min: 2.4, max: 2812.5),
                CappedCareGapAssignmentRequiredCodeRule(message: "capped care gap assignment needs a value"),
                CappedCareGapAssignmentAllowedSourceRule(allowed: ["primary", "rolling"]),
                CappedCareGapAssignmentSourceLengthRule(maxLength: 32),
            ]
        )
    }
}
