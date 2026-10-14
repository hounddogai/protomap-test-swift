import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier assignment must pass. Check returns its problems, or none.
    protocol CourierAssignmentRule {
        func check(_ item: CourierAssignment) -> [String]
    }

    final class CourierAssignmentRequiredChecksumRule: CourierAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierAssignment) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierAssignmentScoreRangeRule: CourierAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CourierAssignment) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CourierAssignmentChecksumLengthRule: CourierAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierAssignment) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CourierAssignmentPinnedGuardRule: CourierAssignmentRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: CourierAssignment) -> [String] {
            if item.pinned && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class CourierAssignmentRequiredLocaleRule: CourierAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierAssignment) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a courier assignment.
    final class CourierAssignmentValidator {
        var rules: [any CourierAssignmentRule]

        init(rules: [any CourierAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierAssignment) -> [String] {
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

        func requireValid(_ item: CourierAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierAssignment]) -> [String: [String]] {
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

    static func defaultCourierAssignmentValidator() -> CourierAssignmentValidator {
        return CourierAssignmentValidator(
            rules: [
                CourierAssignmentRequiredChecksumRule(message: "courier assignment needs an entry"),
                CourierAssignmentScoreRangeRule(min: 6.3, max: 2505.4),
                CourierAssignmentChecksumLengthRule(maxLength: 3600),
                CourierAssignmentPinnedGuardRule(limit: 8.2),
                CourierAssignmentRequiredLocaleRule(message: "courier assignment needs an entry"),
            ]
        )
    }
}
