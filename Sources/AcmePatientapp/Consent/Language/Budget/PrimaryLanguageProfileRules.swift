import AcmePlatform
import Foundation

extension Consent {
    /// A rule a primary language profile must pass. Check returns its problems, or none.
    protocol PrimaryLanguageProfileRule {
        func check(_ item: PrimaryLanguageProfile) -> [String]
    }

    final class PrimaryLanguageProfileCreatedAtRangeRule: PrimaryLanguageProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryLanguageProfile) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryLanguageProfileCodeLengthRule: PrimaryLanguageProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryLanguageProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryLanguageProfileAllowedCodeRule: PrimaryLanguageProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryLanguageProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class PrimaryLanguageProfileTitleLengthRule: PrimaryLanguageProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryLanguageProfile) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryLanguageProfileLimitRangeRule: PrimaryLanguageProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryLanguageProfile) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary language profile.
    final class PrimaryLanguageProfileValidator {
        var rules: [any PrimaryLanguageProfileRule]

        init(rules: [any PrimaryLanguageProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryLanguageProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryLanguageProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryLanguageProfile]) -> [String: [String]] {
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

    static func defaultPrimaryLanguageProfileValidator() -> PrimaryLanguageProfileValidator {
        return PrimaryLanguageProfileValidator(
            rules: [
                PrimaryLanguageProfileCreatedAtRangeRule(min: 80, max: 120),
                PrimaryLanguageProfileCodeLengthRule(maxLength: 80),
                PrimaryLanguageProfileAllowedCodeRule(allowed: ["tiered"]),
                PrimaryLanguageProfileTitleLengthRule(maxLength: 255),
                PrimaryLanguageProfileLimitRangeRule(min: 120, max: 1000),
            ]
        )
    }
}
