import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range request must pass. Check returns its problems, or none.
    protocol ReferenceRangeRequestRule {
        func check(_ item: ReferenceRangeRequest) -> [String]
    }

    final class ReferenceRangeRequestRequiredLabelRule: ReferenceRangeRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeRequest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeRequestAllowedLabelRule: ReferenceRangeRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferenceRangeRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is blocked"]
            }
            return []
        }
    }

    final class ReferenceRangeRequestEndsAtRangeRule: ReferenceRangeRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeRequest) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReferenceRangeRequestActiveGuardRule: ReferenceRangeRequestRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ReferenceRangeRequest) -> [String] {
            if item.active && (item.windowDays > limit) {
                return ["window days \(item.windowDays) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class ReferenceRangeRequestDescriptionLengthRule: ReferenceRangeRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeRequest) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a reference range request.
    final class ReferenceRangeRequestValidator {
        var rules: [any ReferenceRangeRequestRule]

        init(rules: [any ReferenceRangeRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeRequest) -> [String] {
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

        func requireValid(_ item: ReferenceRangeRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeRequest]) -> [String: [String]] {
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

    static func defaultReferenceRangeRequestValidator() -> ReferenceRangeRequestValidator {
        return ReferenceRangeRequestValidator(
            rules: [
                ReferenceRangeRequestRequiredLabelRule(message: "reference range request needs a value"),
                ReferenceRangeRequestAllowedLabelRule(allowed: []),
                ReferenceRangeRequestEndsAtRangeRule(min: 16, max: 86400),
                ReferenceRangeRequestActiveGuardRule(limit: 64),
                ReferenceRangeRequestDescriptionLengthRule(maxLength: 255),
            ]
        )
    }
}
