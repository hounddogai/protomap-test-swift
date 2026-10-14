import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a scheduled bed board target must pass. Check returns its problems, or none.
    protocol ScheduledBedBoardTargetRule {
        func check(_ item: ScheduledBedBoardTarget) -> [String]
    }

    final class ScheduledBedBoardTargetCostRangeRule: ScheduledBedBoardTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledBedBoardTarget) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledBedBoardTargetRequiredLabelRule: ScheduledBedBoardTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledBedBoardTarget) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledBedBoardTargetGraceDaysRangeRule: ScheduledBedBoardTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledBedBoardTarget) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledBedBoardTargetAllowedLabelRule: ScheduledBedBoardTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledBedBoardTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is missing"]
            }
            return []
        }
    }

    final class ScheduledBedBoardTargetCodePrefixRule: ScheduledBedBoardTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledBedBoardTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledBedBoardTargetRequiredCodeRule: ScheduledBedBoardTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledBedBoardTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled bed board target.
    final class ScheduledBedBoardTargetValidator {
        var rules: [any ScheduledBedBoardTargetRule]

        init(rules: [any ScheduledBedBoardTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledBedBoardTarget) -> [String] {
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

        func requireValid(_ item: ScheduledBedBoardTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledBedBoardTarget]) -> [String: [String]] {
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

    static func defaultScheduledBedBoardTargetValidator() -> ScheduledBedBoardTargetValidator {
        return ScheduledBedBoardTargetValidator(
            rules: [
                ScheduledBedBoardTargetCostRangeRule(min: 6.5, max: 3169.8),
                ScheduledBedBoardTargetRequiredLabelRule(message: "scheduled bed board target needs an entry"),
                ScheduledBedBoardTargetGraceDaysRangeRule(min: 32, max: 120),
                ScheduledBedBoardTargetAllowedLabelRule(allowed: ["strict"]),
                ScheduledBedBoardTargetCodePrefixRule(prefix: "OPS"),
                ScheduledBedBoardTargetRequiredCodeRule(message: "scheduled bed board target needs this field"),
            ]
        )
    }
}
