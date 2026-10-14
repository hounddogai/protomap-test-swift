import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential notice must pass. Check returns its problems, or none.
    protocol CredentialNoticeRule {
        func check(_ item: CredentialNotice) -> [String]
    }

    final class CredentialNoticeFacilityLengthRule: CredentialNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialNotice) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialNoticeWindowDaysRangeRule: CredentialNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialNotice) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CredentialNoticePayerLengthRule: CredentialNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialNotice) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a credential notice.
    final class CredentialNoticeValidator {
        var rules: [any CredentialNoticeRule]

        init(rules: [any CredentialNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialNotice) -> [String] {
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

        func requireValid(_ item: CredentialNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialNotice]) -> [String: [String]] {
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

    static func defaultCredentialNoticeValidator() -> CredentialNoticeValidator {
        return CredentialNoticeValidator(
            rules: [
                CredentialNoticeFacilityLengthRule(maxLength: 3600),
                CredentialNoticeWindowDaysRangeRule(min: 16, max: 255),
                CredentialNoticePayerLengthRule(maxLength: 1000),
            ]
        )
    }
}
