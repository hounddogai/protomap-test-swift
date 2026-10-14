import AcmePlatform
import Foundation

extension Consent {
    /// A rule a seasonal language request must pass. Check returns its problems, or none.
    protocol SeasonalLanguageRequestRule {
        func check(_ item: SeasonalLanguageRequest) -> [String]
    }

    final class SeasonalLanguageRequestCodeLengthRule: SeasonalLanguageRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalLanguageRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalLanguageRequestCodePrefixRule: SeasonalLanguageRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalLanguageRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalLanguageRequestRequiredCodeRule: SeasonalLanguageRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalLanguageRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalLanguageRequestCapacityRangeRule: SeasonalLanguageRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalLanguageRequest) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalLanguageRequestAllowedNameRule: SeasonalLanguageRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalLanguageRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is too long"]
            }
            return []
        }
    }

    final class SeasonalLanguageRequestNameLengthRule: SeasonalLanguageRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalLanguageRequest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal language request.
    final class SeasonalLanguageRequestValidator {
        var rules: [any SeasonalLanguageRequestRule]

        init(rules: [any SeasonalLanguageRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalLanguageRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalLanguageRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalLanguageRequest]) -> [String: [String]] {
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

    static func defaultSeasonalLanguageRequestValidator() -> SeasonalLanguageRequestValidator {
        return SeasonalLanguageRequestValidator(
            rules: [
                SeasonalLanguageRequestCodeLengthRule(maxLength: 120),
                SeasonalLanguageRequestCodePrefixRule(prefix: "OPS"),
                SeasonalLanguageRequestRequiredCodeRule(message: "seasonal language request needs an entry"),
                SeasonalLanguageRequestCapacityRangeRule(min: 16, max: 86400),
                SeasonalLanguageRequestAllowedNameRule(allowed: []),
                SeasonalLanguageRequestNameLengthRule(maxLength: 80),
            ]
        )
    }
}
