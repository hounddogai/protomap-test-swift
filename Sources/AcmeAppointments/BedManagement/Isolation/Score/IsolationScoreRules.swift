import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation score must pass. Check returns its problems, or none.
    protocol IsolationScoreRule {
        func check(_ item: IsolationScore) -> [String]
    }

    final class IsolationScoreRequiredTitleRule: IsolationScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationScore) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationScoreExternalRefLengthRule: IsolationScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationScore) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationScoreEndsAtRangeRule: IsolationScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationScore) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class IsolationScoreCountryLengthRule: IsolationScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationScore) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationScoreCodePrefixRule: IsolationScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: IsolationScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class IsolationScoreRequiredCountryRule: IsolationScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationScore) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a isolation score.
    final class IsolationScoreValidator {
        var rules: [any IsolationScoreRule]

        init(rules: [any IsolationScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: IsolationScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationScore]) -> [String: [String]] {
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

    static func defaultIsolationScoreValidator() -> IsolationScoreValidator {
        return IsolationScoreValidator(
            rules: [
                IsolationScoreRequiredTitleRule(message: "isolation score needs a value"),
                IsolationScoreExternalRefLengthRule(maxLength: 80),
                IsolationScoreEndsAtRangeRule(min: 80, max: 3600),
                IsolationScoreCountryLengthRule(maxLength: 120),
                IsolationScoreCodePrefixRule(prefix: "OPS"),
                IsolationScoreRequiredCountryRule(message: "isolation score needs a value"),
            ]
        )
    }
}
