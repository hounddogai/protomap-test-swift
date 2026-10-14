import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range override must pass. Check returns its problems, or none.
    protocol ReferenceRangeOverrideRule {
        func check(_ item: ReferenceRangeOverride) -> [String]
    }

    final class ReferenceRangeOverrideApprovedGuardRule: ReferenceRangeOverrideRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ReferenceRangeOverride) -> [String] {
            if item.approved && (item.floorValue > limit) {
                return ["floor value \(item.floorValue) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class ReferenceRangeOverrideAllowedChannelRule: ReferenceRangeOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferenceRangeOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is above maximum"]
            }
            return []
        }
    }

    final class ReferenceRangeOverrideRequiredCodeRule: ReferenceRangeOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeOverrideRefillsRangeRule: ReferenceRangeOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeOverride) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferenceRangeOverrideRequiredTimezoneRule: ReferenceRangeOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeOverride) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a reference range override.
    final class ReferenceRangeOverrideValidator {
        var rules: [any ReferenceRangeOverrideRule]

        init(rules: [any ReferenceRangeOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeOverride) -> [String] {
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

        func requireValid(_ item: ReferenceRangeOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeOverride]) -> [String: [String]] {
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

    static func defaultReferenceRangeOverrideValidator() -> ReferenceRangeOverrideValidator {
        return ReferenceRangeOverrideValidator(
            rules: [
                ReferenceRangeOverrideApprovedGuardRule(limit: 2.6),
                ReferenceRangeOverrideAllowedChannelRule(allowed: ["fallback", "weighted"]),
                ReferenceRangeOverrideRequiredCodeRule(message: "reference range override needs an entry"),
                ReferenceRangeOverrideRefillsRangeRule(min: 32, max: 120),
                ReferenceRangeOverrideRequiredTimezoneRule(message: "reference range override needs this field"),
            ]
        )
    }
}
