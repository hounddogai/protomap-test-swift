import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession quota must pass. Check returns its problems, or none.
    protocol AccessionQuotaRule {
        func check(_ item: AccessionQuota) -> [String]
    }

    final class AccessionQuotaQuantityRangeRule: AccessionQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionQuota) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AccessionQuotaRequiredAllergyRule: AccessionQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionQuota) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionQuotaBatchSizeRangeRule: AccessionQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionQuota) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a accession quota.
    final class AccessionQuotaValidator {
        var rules: [any AccessionQuotaRule]

        init(rules: [any AccessionQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionQuota) -> [String] {
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

        func requireValid(_ item: AccessionQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionQuota]) -> [String: [String]] {
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

    static func defaultAccessionQuotaValidator() -> AccessionQuotaValidator {
        return AccessionQuotaValidator(
            rules: [
                AccessionQuotaQuantityRangeRule(min: 64, max: 80),
                AccessionQuotaRequiredAllergyRule(message: "accession quota needs an entry"),
                AccessionQuotaBatchSizeRangeRule(min: 255, max: 1000),
            ]
        )
    }
}
