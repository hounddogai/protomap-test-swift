import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a legacy care gap quota must pass. Check returns its problems, or none.
    protocol LegacyCareGapQuotaRule {
        func check(_ item: LegacyCareGapQuota) -> [String]
    }

    final class LegacyCareGapQuotaCodeLengthRule: LegacyCareGapQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyCareGapQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyCareGapQuotaRequiredChannelRule: LegacyCareGapQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyCareGapQuota) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyCareGapQuotaLabelLengthRule: LegacyCareGapQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyCareGapQuota) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyCareGapQuotaWindowDaysRangeRule: LegacyCareGapQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyCareGapQuota) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy care gap quota.
    final class LegacyCareGapQuotaValidator {
        var rules: [any LegacyCareGapQuotaRule]

        init(rules: [any LegacyCareGapQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyCareGapQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyCareGapQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyCareGapQuota]) -> [String: [String]] {
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

    static func defaultLegacyCareGapQuotaValidator() -> LegacyCareGapQuotaValidator {
        return LegacyCareGapQuotaValidator(
            rules: [
                LegacyCareGapQuotaCodeLengthRule(maxLength: 86400),
                LegacyCareGapQuotaRequiredChannelRule(message: "legacy care gap quota needs a value"),
                LegacyCareGapQuotaLabelLengthRule(maxLength: 3600),
                LegacyCareGapQuotaWindowDaysRangeRule(min: 16, max: 32),
            ]
        )
    }
}
