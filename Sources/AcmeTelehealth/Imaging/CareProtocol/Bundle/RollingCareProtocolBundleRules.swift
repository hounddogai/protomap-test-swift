import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a rolling care protocol bundle must pass. Check returns its problems, or none.
    protocol RollingCareProtocolBundleRule {
        func check(_ item: RollingCareProtocolBundle) -> [String]
    }

    final class RollingCareProtocolBundleCodeLengthRule: RollingCareProtocolBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingCareProtocolBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingCareProtocolBundleTitleLengthRule: RollingCareProtocolBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingCareProtocolBundle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingCareProtocolBundleRequiredSummaryRule: RollingCareProtocolBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingCareProtocolBundle) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingCareProtocolBundleSummaryLengthRule: RollingCareProtocolBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingCareProtocolBundle) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingCareProtocolBundleGraceDaysRangeRule: RollingCareProtocolBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingCareProtocolBundle) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling care protocol bundle.
    final class RollingCareProtocolBundleValidator {
        var rules: [any RollingCareProtocolBundleRule]

        init(rules: [any RollingCareProtocolBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingCareProtocolBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingCareProtocolBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingCareProtocolBundle]) -> [String: [String]] {
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

    static func defaultRollingCareProtocolBundleValidator() -> RollingCareProtocolBundleValidator {
        return RollingCareProtocolBundleValidator(
            rules: [
                RollingCareProtocolBundleCodeLengthRule(maxLength: 255),
                RollingCareProtocolBundleTitleLengthRule(maxLength: 3600),
                RollingCareProtocolBundleRequiredSummaryRule(message: "rolling care protocol bundle needs this field"),
                RollingCareProtocolBundleSummaryLengthRule(maxLength: 16),
                RollingCareProtocolBundleGraceDaysRangeRule(min: 16, max: 1000),
            ]
        )
    }
}
