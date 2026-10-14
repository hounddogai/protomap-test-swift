import AcmePlatform
import Foundation

extension Labs {
    /// A rule a pending courier assignment must pass. Check returns its problems, or none.
    protocol PendingCourierAssignmentRule {
        func check(_ item: PendingCourierAssignment) -> [String]
    }

    final class PendingCourierAssignmentCodePrefixRule: PendingCourierAssignmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingCourierAssignment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingCourierAssignmentRequiredFacilityRule: PendingCourierAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCourierAssignment) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingCourierAssignmentRatioRangeRule: PendingCourierAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCourierAssignment) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingCourierAssignmentMaximumRangeRule: PendingCourierAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCourierAssignment) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingCourierAssignmentCodeLengthRule: PendingCourierAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCourierAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending courier assignment.
    final class PendingCourierAssignmentValidator {
        var rules: [any PendingCourierAssignmentRule]

        init(rules: [any PendingCourierAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingCourierAssignment) -> [String] {
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

        func requireValid(_ item: PendingCourierAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingCourierAssignment]) -> [String: [String]] {
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

    static func defaultPendingCourierAssignmentValidator() -> PendingCourierAssignmentValidator {
        return PendingCourierAssignmentValidator(
            rules: [
                PendingCourierAssignmentCodePrefixRule(prefix: "OPS"),
                PendingCourierAssignmentRequiredFacilityRule(message: "pending courier assignment needs an entry"),
                PendingCourierAssignmentRatioRangeRule(min: 4.8, max: 1458.2),
                PendingCourierAssignmentMaximumRangeRule(min: 9.9, max: 2322.2),
                PendingCourierAssignmentCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
