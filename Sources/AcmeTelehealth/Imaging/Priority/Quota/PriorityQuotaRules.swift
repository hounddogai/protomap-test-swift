import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority quota must pass. Check returns its problems, or none.
    protocol PriorityQuotaRule {
        func check(_ item: PriorityQuota) -> [String]
    }

    final class PriorityQuotaLabelLengthRule: PriorityQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityQuota) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityQuotaAcuityRangeRule: PriorityQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityQuota) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PriorityQuotaRequiredAllergyRule: PriorityQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityQuota) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityQuotaSummaryLengthRule: PriorityQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityQuota) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a priority quota.
    final class PriorityQuotaValidator {
        var rules: [any PriorityQuotaRule]

        init(rules: [any PriorityQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PriorityQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityQuota]) -> [String: [String]] {
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

    static func defaultPriorityQuotaValidator() -> PriorityQuotaValidator {
        return PriorityQuotaValidator(
            rules: [
                PriorityQuotaLabelLengthRule(maxLength: 32),
                PriorityQuotaAcuityRangeRule(min: 16, max: 120),
                PriorityQuotaRequiredAllergyRule(message: "priority quota needs a value"),
                PriorityQuotaSummaryLengthRule(maxLength: 16),
            ]
        )
    }
}
