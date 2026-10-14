import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol group must pass. Check returns its problems, or none.
    protocol CareProtocolGroupRule {
        func check(_ item: CareProtocolGroup) -> [String]
    }

    final class CareProtocolGroupAllowedCodeRule: CareProtocolGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareProtocolGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class CareProtocolGroupCreatedAtRangeRule: CareProtocolGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolGroup) -> [String] {
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

    final class CareProtocolGroupCapacityRangeRule: CareProtocolGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolGroup) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareProtocolGroupLabelLengthRule: CareProtocolGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolGroup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol group.
    final class CareProtocolGroupValidator {
        var rules: [any CareProtocolGroupRule]

        init(rules: [any CareProtocolGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolGroup) -> [String] {
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

        func requireValid(_ item: CareProtocolGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolGroup]) -> [String: [String]] {
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

    static func defaultCareProtocolGroupValidator() -> CareProtocolGroupValidator {
        return CareProtocolGroupValidator(
            rules: [
                CareProtocolGroupAllowedCodeRule(allowed: ["batched", "pending", "batched"]),
                CareProtocolGroupCreatedAtRangeRule(min: 255, max: 255),
                CareProtocolGroupCapacityRangeRule(min: 80, max: 1000),
                CareProtocolGroupLabelLengthRule(maxLength: 1000),
            ]
        )
    }
}
