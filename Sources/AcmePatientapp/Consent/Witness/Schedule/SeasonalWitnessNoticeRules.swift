import AcmePlatform
import Foundation

extension Consent {
    /// A rule a seasonal witness notice must pass. Check returns its problems, or none.
    protocol SeasonalWitnessNoticeRule {
        func check(_ item: SeasonalWitnessNotice) -> [String]
    }

    final class SeasonalWitnessNoticeNameLengthRule: SeasonalWitnessNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalWitnessNotice) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalWitnessNoticeMinimumRangeRule: SeasonalWitnessNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalWitnessNotice) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalWitnessNoticeRequiredExternalRefRule: SeasonalWitnessNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalWitnessNotice) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal witness notice.
    final class SeasonalWitnessNoticeValidator {
        var rules: [any SeasonalWitnessNoticeRule]

        init(rules: [any SeasonalWitnessNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalWitnessNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalWitnessNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalWitnessNotice]) -> [String: [String]] {
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

    static func defaultSeasonalWitnessNoticeValidator() -> SeasonalWitnessNoticeValidator {
        return SeasonalWitnessNoticeValidator(
            rules: [
                SeasonalWitnessNoticeNameLengthRule(maxLength: 255),
                SeasonalWitnessNoticeMinimumRangeRule(min: 1.5, max: 3252.8),
                SeasonalWitnessNoticeRequiredExternalRefRule(message: "seasonal witness notice needs a value"),
            ]
        )
    }
}
