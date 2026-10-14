import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range cycle must pass. Check returns its problems, or none.
    protocol ReferenceRangeCycleRule {
        func check(_ item: ReferenceRangeCycle) -> [String]
    }

    final class ReferenceRangeCycleRequiredCodeRule: ReferenceRangeCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeCycleCreatedAtRangeRule: ReferenceRangeCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeCycle) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReferenceRangeCycleRequiredLabelRule: ReferenceRangeCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeCycle) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeCycleAllowedLabelRule: ReferenceRangeCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferenceRangeCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is blocked"]
            }
            return []
        }
    }

    final class ReferenceRangeCyclePinnedGuardRule: ReferenceRangeCycleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ReferenceRangeCycle) -> [String] {
            if item.pinned && (item.createdAt > limit) {
                return ["created at \(item.createdAt) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    /// Runs every rule of a reference range cycle.
    final class ReferenceRangeCycleValidator {
        var rules: [any ReferenceRangeCycleRule]

        init(rules: [any ReferenceRangeCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferenceRangeCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeCycle]) -> [String: [String]] {
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

    static func defaultReferenceRangeCycleValidator() -> ReferenceRangeCycleValidator {
        return ReferenceRangeCycleValidator(
            rules: [
                ReferenceRangeCycleRequiredCodeRule(message: "reference range cycle needs a value"),
                ReferenceRangeCycleCreatedAtRangeRule(min: 16, max: 3600),
                ReferenceRangeCycleRequiredLabelRule(message: "reference range cycle needs an entry"),
                ReferenceRangeCycleAllowedLabelRule(allowed: []),
                ReferenceRangeCyclePinnedGuardRule(limit: 120),
            ]
        )
    }
}
