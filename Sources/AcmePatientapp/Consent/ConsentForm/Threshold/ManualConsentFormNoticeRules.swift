import AcmePlatform
import Foundation

extension Consent {
    /// A rule a manual consent form notice must pass. Check returns its problems, or none.
    protocol ManualConsentFormNoticeRule {
        func check(_ item: ManualConsentFormNotice) -> [String]
    }

    final class ManualConsentFormNoticeAttemptsRangeRule: ManualConsentFormNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualConsentFormNotice) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualConsentFormNoticeRegionLengthRule: ManualConsentFormNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualConsentFormNotice) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualConsentFormNoticeStartsAtRangeRule: ManualConsentFormNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualConsentFormNotice) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualConsentFormNoticeCodeLengthRule: ManualConsentFormNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualConsentFormNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual consent form notice.
    final class ManualConsentFormNoticeValidator {
        var rules: [any ManualConsentFormNoticeRule]

        init(rules: [any ManualConsentFormNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualConsentFormNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualConsentFormNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualConsentFormNotice]) -> [String: [String]] {
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

    static func defaultManualConsentFormNoticeValidator() -> ManualConsentFormNoticeValidator {
        return ManualConsentFormNoticeValidator(
            rules: [
                ManualConsentFormNoticeAttemptsRangeRule(min: 16, max: 86400),
                ManualConsentFormNoticeRegionLengthRule(maxLength: 1000),
                ManualConsentFormNoticeStartsAtRangeRule(min: 32, max: 255),
                ManualConsentFormNoticeCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
