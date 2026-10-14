import AcmePlatform
import Foundation

extension Consent {
    /// A rule a manual disclosure tier must pass. Check returns its problems, or none.
    protocol ManualDisclosureTierRule {
        func check(_ item: ManualDisclosureTier) -> [String]
    }

    final class ManualDisclosureTierFacilityLengthRule: ManualDisclosureTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualDisclosureTier) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualDisclosureTierRequiredNameRule: ManualDisclosureTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualDisclosureTier) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualDisclosureTierStartsAtRangeRule: ManualDisclosureTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualDisclosureTier) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualDisclosureTierAllowedCodeRule: ManualDisclosureTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualDisclosureTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class ManualDisclosureTierSequenceRangeRule: ManualDisclosureTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualDisclosureTier) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual disclosure tier.
    final class ManualDisclosureTierValidator {
        var rules: [any ManualDisclosureTierRule]

        init(rules: [any ManualDisclosureTierRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualDisclosureTier) -> [String] {
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

        func requireValid(_ item: ManualDisclosureTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualDisclosureTier]) -> [String: [String]] {
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

    static func defaultManualDisclosureTierValidator() -> ManualDisclosureTierValidator {
        return ManualDisclosureTierValidator(
            rules: [
                ManualDisclosureTierFacilityLengthRule(maxLength: 16),
                ManualDisclosureTierRequiredNameRule(message: "manual disclosure tier needs a value"),
                ManualDisclosureTierStartsAtRangeRule(min: 1000, max: 3600),
                ManualDisclosureTierAllowedCodeRule(allowed: ["scheduled"]),
                ManualDisclosureTierSequenceRangeRule(min: 16, max: 32),
            ]
        )
    }
}
