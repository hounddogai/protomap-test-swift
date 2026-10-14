import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a global care gap assignment must pass. Check returns its problems, or none.
    protocol GlobalCareGapAssignmentRule {
        func check(_ item: GlobalCareGapAssignment) -> [String]
    }

    final class GlobalCareGapAssignmentRequiredUnitRule: GlobalCareGapAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCareGapAssignment) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCareGapAssignmentCopayRangeRule: GlobalCareGapAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalCareGapAssignment) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalCareGapAssignmentRequiredNameRule: GlobalCareGapAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCareGapAssignment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCareGapAssignmentUpdatedAtRangeRule: GlobalCareGapAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalCareGapAssignment) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a global care gap assignment.
    final class GlobalCareGapAssignmentValidator {
        var rules: [any GlobalCareGapAssignmentRule]

        init(rules: [any GlobalCareGapAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalCareGapAssignment) -> [String] {
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

        func requireValid(_ item: GlobalCareGapAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalCareGapAssignment]) -> [String: [String]] {
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

    static func defaultGlobalCareGapAssignmentValidator() -> GlobalCareGapAssignmentValidator {
        return GlobalCareGapAssignmentValidator(
            rules: [
                GlobalCareGapAssignmentRequiredUnitRule(message: "global care gap assignment needs this field"),
                GlobalCareGapAssignmentCopayRangeRule(min: 3.9, max: 2652.8),
                GlobalCareGapAssignmentRequiredNameRule(message: "global care gap assignment needs this field"),
                GlobalCareGapAssignmentUpdatedAtRangeRule(min: 255, max: 3600),
            ]
        )
    }
}
