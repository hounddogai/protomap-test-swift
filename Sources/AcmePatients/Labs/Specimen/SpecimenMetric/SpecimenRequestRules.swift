import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen request must pass. Check returns its problems, or none.
    protocol SpecimenRequestRule {
        func check(_ item: SpecimenRequest) -> [String]
    }

    final class SpecimenRequestCountryLengthRule: SpecimenRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenRequest) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenRequestBatchSizeRangeRule: SpecimenRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenRequest) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SpecimenRequestRequiredChannelRule: SpecimenRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenRequest) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenRequestExpiresAtRangeRule: SpecimenRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenRequest) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a specimen request.
    final class SpecimenRequestValidator {
        var rules: [any SpecimenRequestRule]

        init(rules: [any SpecimenRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SpecimenRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenRequest]) -> [String: [String]] {
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

    static func defaultSpecimenRequestValidator() -> SpecimenRequestValidator {
        return SpecimenRequestValidator(
            rules: [
                SpecimenRequestCountryLengthRule(maxLength: 80),
                SpecimenRequestBatchSizeRangeRule(min: 16, max: 80),
                SpecimenRequestRequiredChannelRule(message: "specimen request needs this field"),
                SpecimenRequestExpiresAtRangeRule(min: 64, max: 86400),
            ]
        )
    }
}
