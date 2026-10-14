import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a manual priority target must pass. Check returns its problems, or none.
    protocol ManualPriorityTargetRule {
        func check(_ item: ManualPriorityTarget) -> [String]
    }

    final class ManualPriorityTargetRequiredCodeRule: ManualPriorityTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualPriorityTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualPriorityTargetAllowedLabelRule: ManualPriorityTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualPriorityTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is out of range"]
            }
            return []
        }
    }

    final class ManualPriorityTargetRequiredLabelRule: ManualPriorityTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualPriorityTarget) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualPriorityTargetPriorityRangeRule: ManualPriorityTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualPriorityTarget) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualPriorityTargetBedLengthRule: ManualPriorityTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualPriorityTarget) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual priority target.
    final class ManualPriorityTargetValidator {
        var rules: [any ManualPriorityTargetRule]

        init(rules: [any ManualPriorityTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualPriorityTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualPriorityTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualPriorityTarget]) -> [String: [String]] {
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

    static func defaultManualPriorityTargetValidator() -> ManualPriorityTargetValidator {
        return ManualPriorityTargetValidator(
            rules: [
                ManualPriorityTargetRequiredCodeRule(message: "manual priority target needs an entry"),
                ManualPriorityTargetAllowedLabelRule(allowed: ["pending", "fallback"]),
                ManualPriorityTargetRequiredLabelRule(message: "manual priority target needs a value"),
                ManualPriorityTargetPriorityRangeRule(min: 80, max: 3600),
                ManualPriorityTargetBedLengthRule(maxLength: 255),
            ]
        )
    }
}
