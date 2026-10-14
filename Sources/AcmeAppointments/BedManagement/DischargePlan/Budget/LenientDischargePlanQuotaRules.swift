import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a lenient discharge plan quota must pass. Check returns its problems, or none.
    protocol LenientDischargePlanQuotaRule {
        func check(_ item: LenientDischargePlanQuota) -> [String]
    }

    final class LenientDischargePlanQuotaLabelLengthRule: LenientDischargePlanQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientDischargePlanQuota) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientDischargePlanQuotaFloorValueRangeRule: LenientDischargePlanQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientDischargePlanQuota) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientDischargePlanQuotaRequiredTitleRule: LenientDischargePlanQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientDischargePlanQuota) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientDischargePlanQuotaRequiredEncounterIDRule: LenientDischargePlanQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientDischargePlanQuota) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientDischargePlanQuotaRequiredCodeRule: LenientDischargePlanQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientDischargePlanQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientDischargePlanQuotaTitleLengthRule: LenientDischargePlanQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientDischargePlanQuota) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient discharge plan quota.
    final class LenientDischargePlanQuotaValidator {
        var rules: [any LenientDischargePlanQuotaRule]

        init(rules: [any LenientDischargePlanQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientDischargePlanQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientDischargePlanQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientDischargePlanQuota]) -> [String: [String]] {
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

    static func defaultLenientDischargePlanQuotaValidator() -> LenientDischargePlanQuotaValidator {
        return LenientDischargePlanQuotaValidator(
            rules: [
                LenientDischargePlanQuotaLabelLengthRule(maxLength: 1000),
                LenientDischargePlanQuotaFloorValueRangeRule(min: 1.6, max: 1794.4),
                LenientDischargePlanQuotaRequiredTitleRule(message: "lenient discharge plan quota needs a value"),
                LenientDischargePlanQuotaRequiredEncounterIDRule(
                    message: "lenient discharge plan quota needs a value"
                ),
                LenientDischargePlanQuotaRequiredCodeRule(message: "lenient discharge plan quota needs an entry"),
                LenientDischargePlanQuotaTitleLengthRule(maxLength: 120),
            ]
        )
    }
}
