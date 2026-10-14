import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a lenient claim record must pass. Check returns its problems, or none.
    protocol LenientClaimRecordRule {
        func check(_ item: LenientClaimRecord) -> [String]
    }

    final class LenientClaimRecordCodeLengthRule: LenientClaimRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientClaimRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientClaimRecordTitleLengthRule: LenientClaimRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientClaimRecord) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientClaimRecordRetriesRangeRule: LenientClaimRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientClaimRecord) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientClaimRecordLabelLengthRule: LenientClaimRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientClaimRecord) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientClaimRecordVisibleGuardRule: LenientClaimRecordRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: LenientClaimRecord) -> [String] {
            if item.visible && (item.retries > limit) {
                return ["retries \(item.retries) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient claim record.
    final class LenientClaimRecordValidator {
        var rules: [any LenientClaimRecordRule]

        init(rules: [any LenientClaimRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientClaimRecord) -> [String] {
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

        func requireValid(_ item: LenientClaimRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientClaimRecord]) -> [String: [String]] {
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

    static func defaultLenientClaimRecordValidator() -> LenientClaimRecordValidator {
        return LenientClaimRecordValidator(
            rules: [
                LenientClaimRecordCodeLengthRule(maxLength: 1000),
                LenientClaimRecordTitleLengthRule(maxLength: 80),
                LenientClaimRecordRetriesRangeRule(min: 3600, max: 3600),
                LenientClaimRecordLabelLengthRule(maxLength: 64),
                LenientClaimRecordVisibleGuardRule(limit: 3600),
            ]
        )
    }
}
