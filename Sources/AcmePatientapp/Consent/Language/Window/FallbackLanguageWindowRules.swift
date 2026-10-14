import AcmePlatform
import Foundation

extension Consent {
    /// A rule a fallback language window must pass. Check returns its problems, or none.
    protocol FallbackLanguageWindowRule {
        func check(_ item: FallbackLanguageWindow) -> [String]
    }

    final class FallbackLanguageWindowFloorValueRangeRule: FallbackLanguageWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackLanguageWindow) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackLanguageWindowCodeLengthRule: FallbackLanguageWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackLanguageWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackLanguageWindowRequiredExternalRefRule: FallbackLanguageWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackLanguageWindow) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback language window.
    final class FallbackLanguageWindowValidator {
        var rules: [any FallbackLanguageWindowRule]

        init(rules: [any FallbackLanguageWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackLanguageWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackLanguageWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackLanguageWindow]) -> [String: [String]] {
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

    static func defaultFallbackLanguageWindowValidator() -> FallbackLanguageWindowValidator {
        return FallbackLanguageWindowValidator(
            rules: [
                FallbackLanguageWindowFloorValueRangeRule(min: 0.3, max: 509.8),
                FallbackLanguageWindowCodeLengthRule(maxLength: 255),
                FallbackLanguageWindowRequiredExternalRefRule(message: "fallback language window needs an entry"),
            ]
        )
    }
}
