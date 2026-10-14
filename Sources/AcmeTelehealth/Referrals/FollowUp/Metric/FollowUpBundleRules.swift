import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up bundle must pass. Check returns its problems, or none.
    protocol FollowUpBundleRule {
        func check(_ item: FollowUpBundle) -> [String]
    }

    final class FollowUpBundleRequiredCodeRule: FollowUpBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpBundleVisitMinutesRangeRule: FollowUpBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpBundle) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FollowUpBundleCodeLengthRule: FollowUpBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpBundleContactEmailLengthRule: FollowUpBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpBundle) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpBundleLabelLengthRule: FollowUpBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpBundle) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a follow up bundle.
    final class FollowUpBundleValidator {
        var rules: [any FollowUpBundleRule]

        init(rules: [any FollowUpBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpBundle) -> [String] {
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

        func requireValid(_ item: FollowUpBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpBundle]) -> [String: [String]] {
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

    static func defaultFollowUpBundleValidator() -> FollowUpBundleValidator {
        return FollowUpBundleValidator(
            rules: [
                FollowUpBundleRequiredCodeRule(message: "follow up bundle needs an entry"),
                FollowUpBundleVisitMinutesRangeRule(min: 32, max: 64),
                FollowUpBundleCodeLengthRule(maxLength: 1000),
                FollowUpBundleContactEmailLengthRule(maxLength: 86400),
                FollowUpBundleLabelLengthRule(maxLength: 3600),
            ]
        )
    }
}
