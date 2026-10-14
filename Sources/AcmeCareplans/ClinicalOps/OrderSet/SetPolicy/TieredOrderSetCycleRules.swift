import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a tiered order set cycle must pass. Check returns its problems, or none.
    protocol TieredOrderSetCycleRule {
        func check(_ item: TieredOrderSetCycle) -> [String]
    }

    final class TieredOrderSetCycleVisitMinutesRangeRule: TieredOrderSetCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredOrderSetCycle) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredOrderSetCycleRequiredLabelRule: TieredOrderSetCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredOrderSetCycle) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredOrderSetCycleVersionRangeRule: TieredOrderSetCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredOrderSetCycle) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredOrderSetCycleLabelLengthRule: TieredOrderSetCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredOrderSetCycle) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredOrderSetCycleRequiredCodeRule: TieredOrderSetCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredOrderSetCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredOrderSetCycleAllowedCodeRule: TieredOrderSetCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredOrderSetCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered order set cycle.
    final class TieredOrderSetCycleValidator {
        var rules: [any TieredOrderSetCycleRule]

        init(rules: [any TieredOrderSetCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredOrderSetCycle) -> [String] {
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

        func requireValid(_ item: TieredOrderSetCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredOrderSetCycle]) -> [String: [String]] {
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

    static func defaultTieredOrderSetCycleValidator() -> TieredOrderSetCycleValidator {
        return TieredOrderSetCycleValidator(
            rules: [
                TieredOrderSetCycleVisitMinutesRangeRule(min: 255, max: 1000),
                TieredOrderSetCycleRequiredLabelRule(message: "tiered order set cycle needs a value"),
                TieredOrderSetCycleVersionRangeRule(min: 64, max: 64),
                TieredOrderSetCycleLabelLengthRule(maxLength: 86400),
                TieredOrderSetCycleRequiredCodeRule(message: "tiered order set cycle needs an entry"),
                TieredOrderSetCycleAllowedCodeRule(allowed: ["default"]),
            ]
        )
    }
}
