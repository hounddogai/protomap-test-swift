import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a adaptive care gap bundle must pass. Check returns its problems, or none.
    protocol AdaptiveCareGapBundleRule {
        func check(_ item: AdaptiveCareGapBundle) -> [String]
    }

    final class AdaptiveCareGapBundleNotesLengthRule: AdaptiveCareGapBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveCareGapBundle) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveCareGapBundleActiveGuardRule: AdaptiveCareGapBundleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: AdaptiveCareGapBundle) -> [String] {
            if item.active && (item.graceDays > limit) {
                return ["grace days \(item.graceDays) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class AdaptiveCareGapBundleCodePrefixRule: AdaptiveCareGapBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveCareGapBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveCareGapBundleUpdatedAtRangeRule: AdaptiveCareGapBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveCareGapBundle) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveCareGapBundleCodeLengthRule: AdaptiveCareGapBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveCareGapBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive care gap bundle.
    final class AdaptiveCareGapBundleValidator {
        var rules: [any AdaptiveCareGapBundleRule]

        init(rules: [any AdaptiveCareGapBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveCareGapBundle) -> [String] {
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

        func requireValid(_ item: AdaptiveCareGapBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveCareGapBundle]) -> [String: [String]] {
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

    static func defaultAdaptiveCareGapBundleValidator() -> AdaptiveCareGapBundleValidator {
        return AdaptiveCareGapBundleValidator(
            rules: [
                AdaptiveCareGapBundleNotesLengthRule(maxLength: 1000),
                AdaptiveCareGapBundleActiveGuardRule(limit: 255),
                AdaptiveCareGapBundleCodePrefixRule(prefix: "Q"),
                AdaptiveCareGapBundleUpdatedAtRangeRule(min: 86400, max: 86400),
                AdaptiveCareGapBundleCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
