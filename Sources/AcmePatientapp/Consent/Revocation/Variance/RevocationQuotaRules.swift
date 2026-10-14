import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation quota must pass. Check returns its problems, or none.
    protocol RevocationQuotaRule {
        func check(_ item: RevocationQuota) -> [String]
    }

    final class RevocationQuotaFacilityLengthRule: RevocationQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationQuota) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationQuotaRatioRangeRule: RevocationQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RevocationQuota) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RevocationQuotaAllowedSpecialtyRule: RevocationQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RevocationQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a revocation quota.
    final class RevocationQuotaValidator {
        var rules: [any RevocationQuotaRule]

        init(rules: [any RevocationQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RevocationQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationQuota]) -> [String: [String]] {
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

    static func defaultRevocationQuotaValidator() -> RevocationQuotaValidator {
        return RevocationQuotaValidator(
            rules: [
                RevocationQuotaFacilityLengthRule(maxLength: 80),
                RevocationQuotaRatioRangeRule(min: 0.4, max: 1308.1),
                RevocationQuotaAllowedSpecialtyRule(allowed: ["tiered", "seasonal"]),
            ]
        )
    }
}
