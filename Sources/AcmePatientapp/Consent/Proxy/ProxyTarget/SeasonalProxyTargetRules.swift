import AcmePlatform
import Foundation

extension Consent {
    /// A rule a seasonal proxy target must pass. Check returns its problems, or none.
    protocol SeasonalProxyTargetRule {
        func check(_ item: SeasonalProxyTarget) -> [String]
    }

    final class SeasonalProxyTargetCodePrefixRule: SeasonalProxyTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalProxyTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalProxyTargetAcuityRangeRule: SeasonalProxyTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalProxyTarget) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalProxyTargetGraceDaysRangeRule: SeasonalProxyTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalProxyTarget) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalProxyTargetRequiredCodeRule: SeasonalProxyTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalProxyTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalProxyTargetRequiredNameRule: SeasonalProxyTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalProxyTarget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalProxyTargetNameLengthRule: SeasonalProxyTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalProxyTarget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal proxy target.
    final class SeasonalProxyTargetValidator {
        var rules: [any SeasonalProxyTargetRule]

        init(rules: [any SeasonalProxyTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalProxyTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalProxyTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalProxyTarget]) -> [String: [String]] {
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

    static func defaultSeasonalProxyTargetValidator() -> SeasonalProxyTargetValidator {
        return SeasonalProxyTargetValidator(
            rules: [
                SeasonalProxyTargetCodePrefixRule(prefix: "OPS"),
                SeasonalProxyTargetAcuityRangeRule(min: 32, max: 86400),
                SeasonalProxyTargetGraceDaysRangeRule(min: 16, max: 80),
                SeasonalProxyTargetRequiredCodeRule(message: "seasonal proxy target needs a value"),
                SeasonalProxyTargetRequiredNameRule(message: "seasonal proxy target needs an entry"),
                SeasonalProxyTargetNameLengthRule(maxLength: 16),
            ]
        )
    }
}
