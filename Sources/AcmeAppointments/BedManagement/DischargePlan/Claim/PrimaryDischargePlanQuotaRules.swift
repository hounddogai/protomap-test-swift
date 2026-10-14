import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a primary discharge plan quota must pass. Check returns its problems, or none.
    protocol PrimaryDischargePlanQuotaRule {
        func check(_ item: PrimaryDischargePlanQuota) -> [String]
    }

    final class PrimaryDischargePlanQuotaThresholdRangeRule: PrimaryDischargePlanQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryDischargePlanQuota) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryDischargePlanQuotaRequiredCodeRule: PrimaryDischargePlanQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryDischargePlanQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryDischargePlanQuotaRequiredNameRule: PrimaryDischargePlanQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryDischargePlanQuota) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryDischargePlanQuotaWindowDaysRangeRule: PrimaryDischargePlanQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryDischargePlanQuota) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryDischargePlanQuotaCodePrefixRule: PrimaryDischargePlanQuotaRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryDischargePlanQuota) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary discharge plan quota.
    final class PrimaryDischargePlanQuotaValidator {
        var rules: [any PrimaryDischargePlanQuotaRule]

        init(rules: [any PrimaryDischargePlanQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryDischargePlanQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryDischargePlanQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryDischargePlanQuota]) -> [String: [String]] {
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

    static func defaultPrimaryDischargePlanQuotaValidator() -> PrimaryDischargePlanQuotaValidator {
        return PrimaryDischargePlanQuotaValidator(
            rules: [
                PrimaryDischargePlanQuotaThresholdRangeRule(min: 8.9, max: 3736.6),
                PrimaryDischargePlanQuotaRequiredCodeRule(message: "primary discharge plan quota needs this field"),
                PrimaryDischargePlanQuotaRequiredNameRule(message: "primary discharge plan quota needs this field"),
                PrimaryDischargePlanQuotaWindowDaysRangeRule(min: 3600, max: 86400),
                PrimaryDischargePlanQuotaCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
