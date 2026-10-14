import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a adaptive inventory audit must pass. Check returns its problems, or none.
    protocol AdaptiveInventoryAuditRule {
        func check(_ item: AdaptiveInventoryAudit) -> [String]
    }

    final class AdaptiveInventoryAuditSummaryLengthRule: AdaptiveInventoryAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveInventoryAudit) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveInventoryAuditCeilingRangeRule: AdaptiveInventoryAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveInventoryAudit) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveInventoryAuditWeightRangeRule: AdaptiveInventoryAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveInventoryAudit) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveInventoryAuditCodeLengthRule: AdaptiveInventoryAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveInventoryAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveInventoryAuditWardLengthRule: AdaptiveInventoryAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveInventoryAudit) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive inventory audit.
    final class AdaptiveInventoryAuditValidator {
        var rules: [any AdaptiveInventoryAuditRule]

        init(rules: [any AdaptiveInventoryAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveInventoryAudit) -> [String] {
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

        func requireValid(_ item: AdaptiveInventoryAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveInventoryAudit]) -> [String: [String]] {
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

    static func defaultAdaptiveInventoryAuditValidator() -> AdaptiveInventoryAuditValidator {
        return AdaptiveInventoryAuditValidator(
            rules: [
                AdaptiveInventoryAuditSummaryLengthRule(maxLength: 16),
                AdaptiveInventoryAuditCeilingRangeRule(min: 9.8, max: 1483.6),
                AdaptiveInventoryAuditWeightRangeRule(min: 7.2, max: 419.8),
                AdaptiveInventoryAuditCodeLengthRule(maxLength: 3600),
                AdaptiveInventoryAuditWardLengthRule(maxLength: 64),
            ]
        )
    }
}
