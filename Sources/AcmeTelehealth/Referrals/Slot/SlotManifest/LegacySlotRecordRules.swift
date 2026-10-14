import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a legacy slot record must pass. Check returns its problems, or none.
    protocol LegacySlotRecordRule {
        func check(_ item: LegacySlotRecord) -> [String]
    }

    final class LegacySlotRecordRequiredTitleRule: LegacySlotRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacySlotRecord) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacySlotRecordRateRangeRule: LegacySlotRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacySlotRecord) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacySlotRecordExternalRefLengthRule: LegacySlotRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacySlotRecord) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacySlotRecordAllowedTitleRule: LegacySlotRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacySlotRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is not allowed"]
            }
            return []
        }
    }

    final class LegacySlotRecordRequiredCodeRule: LegacySlotRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacySlotRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy slot record.
    final class LegacySlotRecordValidator {
        var rules: [any LegacySlotRecordRule]

        init(rules: [any LegacySlotRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacySlotRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacySlotRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacySlotRecord]) -> [String: [String]] {
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

    static func defaultLegacySlotRecordValidator() -> LegacySlotRecordValidator {
        return LegacySlotRecordValidator(
            rules: [
                LegacySlotRecordRequiredTitleRule(message: "legacy slot record needs a value"),
                LegacySlotRecordRateRangeRule(min: 7.8, max: 3513.4),
                LegacySlotRecordExternalRefLengthRule(maxLength: 3600),
                LegacySlotRecordAllowedTitleRule(allowed: ["global"]),
                LegacySlotRecordRequiredCodeRule(message: "legacy slot record needs a value"),
            ]
        )
    }
}
