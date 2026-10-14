import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a weighted worklist request must pass. Check returns its problems, or none.
    protocol WeightedWorklistRequestRule {
        func check(_ item: WeightedWorklistRequest) -> [String]
    }

    final class WeightedWorklistRequestVisibleGuardRule: WeightedWorklistRequestRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: WeightedWorklistRequest) -> [String] {
            if item.visible && (item.startsAt > limit) {
                return ["starts at \(item.startsAt) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class WeightedWorklistRequestEncounterIDLengthRule: WeightedWorklistRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedWorklistRequest) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedWorklistRequestAllowedNotesRule: WeightedWorklistRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedWorklistRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.notes)) {
                return ["notes \(item.notes) is below minimum"]
            }
            return []
        }
    }

    final class WeightedWorklistRequestCeilingRangeRule: WeightedWorklistRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedWorklistRequest) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedWorklistRequestCodeLengthRule: WeightedWorklistRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedWorklistRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedWorklistRequestRequiredNotesRule: WeightedWorklistRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedWorklistRequest) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted worklist request.
    final class WeightedWorklistRequestValidator {
        var rules: [any WeightedWorklistRequestRule]

        init(rules: [any WeightedWorklistRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedWorklistRequest) -> [String] {
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

        func requireValid(_ item: WeightedWorklistRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedWorklistRequest]) -> [String: [String]] {
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

    static func defaultWeightedWorklistRequestValidator() -> WeightedWorklistRequestValidator {
        return WeightedWorklistRequestValidator(
            rules: [
                WeightedWorklistRequestVisibleGuardRule(limit: 3600),
                WeightedWorklistRequestEncounterIDLengthRule(maxLength: 16),
                WeightedWorklistRequestAllowedNotesRule(allowed: []),
                WeightedWorklistRequestCeilingRangeRule(min: 1.3, max: 1899.0),
                WeightedWorklistRequestCodeLengthRule(maxLength: 1000),
                WeightedWorklistRequestRequiredNotesRule(message: "weighted worklist request needs an entry"),
            ]
        )
    }
}
