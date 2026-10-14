import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a adaptive outreach bundle must pass. Check returns its problems, or none.
    protocol AdaptiveOutreachBundleRule {
        func check(_ item: AdaptiveOutreachBundle) -> [String]
    }

    final class AdaptiveOutreachBundleRequiredTitleRule: AdaptiveOutreachBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveOutreachBundle) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveOutreachBundleRequiredEncounterIDRule: AdaptiveOutreachBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveOutreachBundle) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveOutreachBundleCodeLengthRule: AdaptiveOutreachBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveOutreachBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveOutreachBundleEncounterIDLengthRule: AdaptiveOutreachBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveOutreachBundle) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveOutreachBundleAttemptsRangeRule: AdaptiveOutreachBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveOutreachBundle) -> [String] {
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

    final class AdaptiveOutreachBundleCodePrefixRule: AdaptiveOutreachBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveOutreachBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive outreach bundle.
    final class AdaptiveOutreachBundleValidator {
        var rules: [any AdaptiveOutreachBundleRule]

        init(rules: [any AdaptiveOutreachBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveOutreachBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveOutreachBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveOutreachBundle]) -> [String: [String]] {
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

    static func defaultAdaptiveOutreachBundleValidator() -> AdaptiveOutreachBundleValidator {
        return AdaptiveOutreachBundleValidator(
            rules: [
                AdaptiveOutreachBundleRequiredTitleRule(message: "adaptive outreach bundle needs this field"),
                AdaptiveOutreachBundleRequiredEncounterIDRule(message: "adaptive outreach bundle needs this field"),
                AdaptiveOutreachBundleCodeLengthRule(maxLength: 3600),
                AdaptiveOutreachBundleEncounterIDLengthRule(maxLength: 1000),
                AdaptiveOutreachBundleAttemptsRangeRule(min: 32, max: 120),
                AdaptiveOutreachBundleCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
