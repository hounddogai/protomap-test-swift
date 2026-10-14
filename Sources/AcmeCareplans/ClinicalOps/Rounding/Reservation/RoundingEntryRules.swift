import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding entry must pass. Check returns its problems, or none.
    protocol RoundingEntryRule {
        func check(_ item: RoundingEntry) -> [String]
    }

    final class RoundingEntryRequiredLabelRule: RoundingEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingEntry) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingEntryAcuityRangeRule: RoundingEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingEntry) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RoundingEntryApprovedGuardRule: RoundingEntryRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RoundingEntry) -> [String] {
            if item.approved && (item.acuity > limit) {
                return ["acuity \(item.acuity) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class RoundingEntryRequiredCodeRule: RoundingEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingEntryAllowedLabelRule: RoundingEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RoundingEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a rounding entry.
    final class RoundingEntryValidator {
        var rules: [any RoundingEntryRule]

        init(rules: [any RoundingEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RoundingEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingEntry]) -> [String: [String]] {
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

    static func defaultRoundingEntryValidator() -> RoundingEntryValidator {
        return RoundingEntryValidator(
            rules: [
                RoundingEntryRequiredLabelRule(message: "rounding entry needs this field"),
                RoundingEntryAcuityRangeRule(min: 80, max: 3600),
                RoundingEntryApprovedGuardRule(limit: 64),
                RoundingEntryRequiredCodeRule(message: "rounding entry needs this field"),
                RoundingEntryAllowedLabelRule(allowed: ["rolling"]),
            ]
        )
    }
}
