import AcmePlatform
import Foundation

extension Consent {
    /// A rule a capped witness cycle must pass. Check returns its problems, or none.
    protocol CappedWitnessCycleRule {
        func check(_ item: CappedWitnessCycle) -> [String]
    }

    final class CappedWitnessCycleRequiredAllergyRule: CappedWitnessCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedWitnessCycle) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedWitnessCycleCostRangeRule: CappedWitnessCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedWitnessCycle) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedWitnessCycleCodePrefixRule: CappedWitnessCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedWitnessCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedWitnessCycleRequiredLabelRule: CappedWitnessCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedWitnessCycle) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedWitnessCycleTagsLimitRule: CappedWitnessCycleRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: CappedWitnessCycle) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    /// Runs every rule of a capped witness cycle.
    final class CappedWitnessCycleValidator {
        var rules: [any CappedWitnessCycleRule]

        init(rules: [any CappedWitnessCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedWitnessCycle) -> [String] {
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

        func requireValid(_ item: CappedWitnessCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedWitnessCycle]) -> [String: [String]] {
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

    static func defaultCappedWitnessCycleValidator() -> CappedWitnessCycleValidator {
        return CappedWitnessCycleValidator(
            rules: [
                CappedWitnessCycleRequiredAllergyRule(message: "capped witness cycle needs this field"),
                CappedWitnessCycleCostRangeRule(min: 2.5, max: 4071.4),
                CappedWitnessCycleCodePrefixRule(prefix: "REF"),
                CappedWitnessCycleRequiredLabelRule(message: "capped witness cycle needs this field"),
                CappedWitnessCycleTagsLimitRule(maxCount: 3600, banned: ["rolling", "primary"]),
            ]
        )
    }
}
