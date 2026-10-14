import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a seasonal rounding request must pass. Check returns its problems, or none.
    protocol SeasonalRoundingRequestRule {
        func check(_ item: SeasonalRoundingRequest) -> [String]
    }

    final class SeasonalRoundingRequestRequiredNameRule: SeasonalRoundingRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalRoundingRequest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalRoundingRequestGraceDaysRangeRule: SeasonalRoundingRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalRoundingRequest) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalRoundingRequestRequiredUnitRule: SeasonalRoundingRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalRoundingRequest) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalRoundingRequestRequiredSourceRule: SeasonalRoundingRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalRoundingRequest) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal rounding request.
    final class SeasonalRoundingRequestValidator {
        var rules: [any SeasonalRoundingRequestRule]

        init(rules: [any SeasonalRoundingRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalRoundingRequest) -> [String] {
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

        func requireValid(_ item: SeasonalRoundingRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalRoundingRequest]) -> [String: [String]] {
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

    static func defaultSeasonalRoundingRequestValidator() -> SeasonalRoundingRequestValidator {
        return SeasonalRoundingRequestValidator(
            rules: [
                SeasonalRoundingRequestRequiredNameRule(message: "seasonal rounding request needs this field"),
                SeasonalRoundingRequestGraceDaysRangeRule(min: 16, max: 32),
                SeasonalRoundingRequestRequiredUnitRule(message: "seasonal rounding request needs a value"),
                SeasonalRoundingRequestRequiredSourceRule(message: "seasonal rounding request needs this field"),
            ]
        )
    }
}
