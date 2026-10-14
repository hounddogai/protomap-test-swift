import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a capped care gap quota must pass. Check returns its problems, or none.
    protocol CappedCareGapQuotaRule {
        func check(_ item: CappedCareGapQuota) -> [String]
    }

    final class CappedCareGapQuotaFloorValueRangeRule: CappedCareGapQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedCareGapQuota) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedCareGapQuotaUnitLengthRule: CappedCareGapQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedCareGapQuota) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedCareGapQuotaRequiredLabelRule: CappedCareGapQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedCareGapQuota) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedCareGapQuotaRequiredLocaleRule: CappedCareGapQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedCareGapQuota) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped care gap quota.
    final class CappedCareGapQuotaValidator {
        var rules: [any CappedCareGapQuotaRule]

        init(rules: [any CappedCareGapQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedCareGapQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedCareGapQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedCareGapQuota]) -> [String: [String]] {
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

    static func defaultCappedCareGapQuotaValidator() -> CappedCareGapQuotaValidator {
        return CappedCareGapQuotaValidator(
            rules: [
                CappedCareGapQuotaFloorValueRangeRule(min: 0.3, max: 2174.0),
                CappedCareGapQuotaUnitLengthRule(maxLength: 32),
                CappedCareGapQuotaRequiredLabelRule(message: "capped care gap quota needs a value"),
                CappedCareGapQuotaRequiredLocaleRule(message: "capped care gap quota needs a value"),
            ]
        )
    }
}
