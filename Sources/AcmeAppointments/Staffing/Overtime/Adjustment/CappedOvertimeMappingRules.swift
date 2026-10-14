import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a capped overtime mapping must pass. Check returns its problems, or none.
    protocol CappedOvertimeMappingRule {
        func check(_ item: CappedOvertimeMapping) -> [String]
    }

    final class CappedOvertimeMappingCodeLengthRule: CappedOvertimeMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedOvertimeMapping) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedOvertimeMappingTimezoneLengthRule: CappedOvertimeMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedOvertimeMapping) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedOvertimeMappingNameLengthRule: CappedOvertimeMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedOvertimeMapping) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedOvertimeMappingOwnerIDLengthRule: CappedOvertimeMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedOvertimeMapping) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedOvertimeMappingBudgetRangeRule: CappedOvertimeMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedOvertimeMapping) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedOvertimeMappingExpiresAtRangeRule: CappedOvertimeMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedOvertimeMapping) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a capped overtime mapping.
    final class CappedOvertimeMappingValidator {
        var rules: [any CappedOvertimeMappingRule]

        init(rules: [any CappedOvertimeMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedOvertimeMapping) -> [String] {
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

        func requireValid(_ item: CappedOvertimeMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedOvertimeMapping]) -> [String: [String]] {
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

    static func defaultCappedOvertimeMappingValidator() -> CappedOvertimeMappingValidator {
        return CappedOvertimeMappingValidator(
            rules: [
                CappedOvertimeMappingCodeLengthRule(maxLength: 16),
                CappedOvertimeMappingTimezoneLengthRule(maxLength: 3600),
                CappedOvertimeMappingNameLengthRule(maxLength: 32),
                CappedOvertimeMappingOwnerIDLengthRule(maxLength: 80),
                CappedOvertimeMappingBudgetRangeRule(min: 4.6, max: 3149.6),
                CappedOvertimeMappingExpiresAtRangeRule(min: 80, max: 86400),
            ]
        )
    }
}
