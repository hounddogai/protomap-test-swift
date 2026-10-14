import AcmePlatform
import Foundation

extension Labs {
    /// A rule a default specimen quota must pass. Check returns its problems, or none.
    protocol DefaultSpecimenQuotaRule {
        func check(_ item: DefaultSpecimenQuota) -> [String]
    }

    final class DefaultSpecimenQuotaSequenceRangeRule: DefaultSpecimenQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultSpecimenQuota) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultSpecimenQuotaWardLengthRule: DefaultSpecimenQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultSpecimenQuota) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultSpecimenQuotaAllowedWardRule: DefaultSpecimenQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultSpecimenQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a default specimen quota.
    final class DefaultSpecimenQuotaValidator {
        var rules: [any DefaultSpecimenQuotaRule]

        init(rules: [any DefaultSpecimenQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultSpecimenQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultSpecimenQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultSpecimenQuota]) -> [String: [String]] {
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

    static func defaultDefaultSpecimenQuotaValidator() -> DefaultSpecimenQuotaValidator {
        return DefaultSpecimenQuotaValidator(
            rules: [
                DefaultSpecimenQuotaSequenceRangeRule(min: 16, max: 80),
                DefaultSpecimenQuotaWardLengthRule(maxLength: 80),
                DefaultSpecimenQuotaAllowedWardRule(allowed: ["batched", "rolling", "fallback"]),
            ]
        )
    }
}
