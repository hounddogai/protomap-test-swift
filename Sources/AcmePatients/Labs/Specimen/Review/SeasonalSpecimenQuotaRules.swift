import AcmePlatform
import Foundation

extension Labs {
    /// A rule a seasonal specimen quota must pass. Check returns its problems, or none.
    protocol SeasonalSpecimenQuotaRule {
        func check(_ item: SeasonalSpecimenQuota) -> [String]
    }

    final class SeasonalSpecimenQuotaLabelLengthRule: SeasonalSpecimenQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalSpecimenQuota) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalSpecimenQuotaVisitMinutesRangeRule: SeasonalSpecimenQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalSpecimenQuota) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalSpecimenQuotaLimitRangeRule: SeasonalSpecimenQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalSpecimenQuota) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalSpecimenQuotaCodeLengthRule: SeasonalSpecimenQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalSpecimenQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalSpecimenQuotaVisibleGuardRule: SeasonalSpecimenQuotaRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: SeasonalSpecimenQuota) -> [String] {
            if item.visible && (item.limit > limit) {
                return ["limit \(item.limit) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class SeasonalSpecimenQuotaRevisionRangeRule: SeasonalSpecimenQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalSpecimenQuota) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a seasonal specimen quota.
    final class SeasonalSpecimenQuotaValidator {
        var rules: [any SeasonalSpecimenQuotaRule]

        init(rules: [any SeasonalSpecimenQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalSpecimenQuota) -> [String] {
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

        func requireValid(_ item: SeasonalSpecimenQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalSpecimenQuota]) -> [String: [String]] {
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

    static func defaultSeasonalSpecimenQuotaValidator() -> SeasonalSpecimenQuotaValidator {
        return SeasonalSpecimenQuotaValidator(
            rules: [
                SeasonalSpecimenQuotaLabelLengthRule(maxLength: 3600),
                SeasonalSpecimenQuotaVisitMinutesRangeRule(min: 80, max: 80),
                SeasonalSpecimenQuotaLimitRangeRule(min: 64, max: 86400),
                SeasonalSpecimenQuotaCodeLengthRule(maxLength: 120),
                SeasonalSpecimenQuotaVisibleGuardRule(limit: 64),
                SeasonalSpecimenQuotaRevisionRangeRule(min: 86400, max: 86400),
            ]
        )
    }
}
