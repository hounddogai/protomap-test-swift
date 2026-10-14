import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a legacy program summary must pass. Check returns its problems, or none.
    protocol LegacyProgramSummaryRule {
        func check(_ item: LegacyProgramSummary) -> [String]
    }

    final class LegacyProgramSummaryRequiredPhoneRule: LegacyProgramSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyProgramSummary) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyProgramSummaryFloorValueRangeRule: LegacyProgramSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyProgramSummary) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyProgramSummaryTitleLengthRule: LegacyProgramSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyProgramSummary) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyProgramSummaryCodePrefixRule: LegacyProgramSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyProgramSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyProgramSummarySequenceRangeRule: LegacyProgramSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyProgramSummary) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy program summary.
    final class LegacyProgramSummaryValidator {
        var rules: [any LegacyProgramSummaryRule]

        init(rules: [any LegacyProgramSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyProgramSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyProgramSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyProgramSummary]) -> [String: [String]] {
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

    static func defaultLegacyProgramSummaryValidator() -> LegacyProgramSummaryValidator {
        return LegacyProgramSummaryValidator(
            rules: [
                LegacyProgramSummaryRequiredPhoneRule(message: "legacy program summary needs this field"),
                LegacyProgramSummaryFloorValueRangeRule(min: 1.6, max: 485.9),
                LegacyProgramSummaryTitleLengthRule(maxLength: 120),
                LegacyProgramSummaryCodePrefixRule(prefix: "X"),
                LegacyProgramSummarySequenceRangeRule(min: 16, max: 16),
            ]
        )
    }
}
