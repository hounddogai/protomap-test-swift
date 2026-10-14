import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a fallback authorization audit must pass. Check returns its problems, or none.
    protocol FallbackAuthorizationAuditRule {
        func check(_ item: FallbackAuthorizationAudit) -> [String]
    }

    final class FallbackAuthorizationAuditCodeLengthRule: FallbackAuthorizationAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackAuthorizationAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackAuthorizationAuditMaximumRangeRule: FallbackAuthorizationAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackAuthorizationAudit) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackAuthorizationAuditScoreRangeRule: FallbackAuthorizationAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackAuthorizationAudit) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback authorization audit.
    final class FallbackAuthorizationAuditValidator {
        var rules: [any FallbackAuthorizationAuditRule]

        init(rules: [any FallbackAuthorizationAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackAuthorizationAudit) -> [String] {
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

        func requireValid(_ item: FallbackAuthorizationAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackAuthorizationAudit]) -> [String: [String]] {
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

    static func defaultFallbackAuthorizationAuditValidator() -> FallbackAuthorizationAuditValidator {
        return FallbackAuthorizationAuditValidator(
            rules: [
                FallbackAuthorizationAuditCodeLengthRule(maxLength: 16),
                FallbackAuthorizationAuditMaximumRangeRule(min: 5.0, max: 3701.2),
                FallbackAuthorizationAuditScoreRangeRule(min: 6.8, max: 4031.1),
            ]
        )
    }
}
