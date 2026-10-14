import AcmePlatform
import Foundation

extension Labs {
    /// A rule a legacy reference range summary must pass. Check returns its problems, or none.
    protocol LegacyReferenceRangeSummaryRule {
        func check(_ item: LegacyReferenceRangeSummary) -> [String]
    }

    final class LegacyReferenceRangeSummaryRegionLengthRule: LegacyReferenceRangeSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyReferenceRangeSummary) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyReferenceRangeSummaryRequiredCodeRule: LegacyReferenceRangeSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyReferenceRangeSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyReferenceRangeSummaryCodeLengthRule: LegacyReferenceRangeSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyReferenceRangeSummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyReferenceRangeSummaryRequiredRegionRule: LegacyReferenceRangeSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyReferenceRangeSummary) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyReferenceRangeSummaryPinnedGuardRule: LegacyReferenceRangeSummaryRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: LegacyReferenceRangeSummary) -> [String] {
            if item.pinned && (item.dosageMg > limit) {
                return ["dosage mg \(item.dosageMg) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy reference range summary.
    final class LegacyReferenceRangeSummaryValidator {
        var rules: [any LegacyReferenceRangeSummaryRule]

        init(rules: [any LegacyReferenceRangeSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyReferenceRangeSummary) -> [String] {
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

        func requireValid(_ item: LegacyReferenceRangeSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyReferenceRangeSummary]) -> [String: [String]] {
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

    static func defaultLegacyReferenceRangeSummaryValidator() -> LegacyReferenceRangeSummaryValidator {
        return LegacyReferenceRangeSummaryValidator(
            rules: [
                LegacyReferenceRangeSummaryRegionLengthRule(maxLength: 64),
                LegacyReferenceRangeSummaryRequiredCodeRule(message: "legacy reference range summary needs a value"),
                LegacyReferenceRangeSummaryCodeLengthRule(maxLength: 1000),
                LegacyReferenceRangeSummaryRequiredRegionRule(message: "legacy reference range summary needs a value"),
                LegacyReferenceRangeSummaryPinnedGuardRule(limit: 3.9),
            ]
        )
    }
}
