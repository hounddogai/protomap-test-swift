import AcmePlatform
import Foundation

extension Labs {
    /// A rule a capped specimen quota must pass. Check returns its problems, or none.
    protocol CappedSpecimenQuotaRule {
        func check(_ item: CappedSpecimenQuota) -> [String]
    }

    final class CappedSpecimenQuotaCodePrefixRule: CappedSpecimenQuotaRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedSpecimenQuota) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedSpecimenQuotaPatientRefLengthRule: CappedSpecimenQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedSpecimenQuota) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedSpecimenQuotaLabelLengthRule: CappedSpecimenQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedSpecimenQuota) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedSpecimenQuotaDiscountRangeRule: CappedSpecimenQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedSpecimenQuota) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped specimen quota.
    final class CappedSpecimenQuotaValidator {
        var rules: [any CappedSpecimenQuotaRule]

        init(rules: [any CappedSpecimenQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedSpecimenQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedSpecimenQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedSpecimenQuota]) -> [String: [String]] {
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

    static func defaultCappedSpecimenQuotaValidator() -> CappedSpecimenQuotaValidator {
        return CappedSpecimenQuotaValidator(
            rules: [
                CappedSpecimenQuotaCodePrefixRule(prefix: "X"),
                CappedSpecimenQuotaPatientRefLengthRule(maxLength: 86400),
                CappedSpecimenQuotaLabelLengthRule(maxLength: 120),
                CappedSpecimenQuotaDiscountRangeRule(min: 2.7, max: 3744.9),
            ]
        )
    }
}
