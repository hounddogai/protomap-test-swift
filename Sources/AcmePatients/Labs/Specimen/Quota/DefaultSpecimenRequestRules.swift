import AcmePlatform
import Foundation

extension Labs {
    /// A rule a default specimen request must pass. Check returns its problems, or none.
    protocol DefaultSpecimenRequestRule {
        func check(_ item: DefaultSpecimenRequest) -> [String]
    }

    final class DefaultSpecimenRequestLimitRangeRule: DefaultSpecimenRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultSpecimenRequest) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultSpecimenRequestRequiredNameRule: DefaultSpecimenRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultSpecimenRequest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultSpecimenRequestRequiredCodeRule: DefaultSpecimenRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultSpecimenRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultSpecimenRequestPayerLengthRule: DefaultSpecimenRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultSpecimenRequest) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default specimen request.
    final class DefaultSpecimenRequestValidator {
        var rules: [any DefaultSpecimenRequestRule]

        init(rules: [any DefaultSpecimenRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultSpecimenRequest) -> [String] {
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

        func requireValid(_ item: DefaultSpecimenRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultSpecimenRequest]) -> [String: [String]] {
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

    static func defaultDefaultSpecimenRequestValidator() -> DefaultSpecimenRequestValidator {
        return DefaultSpecimenRequestValidator(
            rules: [
                DefaultSpecimenRequestLimitRangeRule(min: 32, max: 255),
                DefaultSpecimenRequestRequiredNameRule(message: "default specimen request needs this field"),
                DefaultSpecimenRequestRequiredCodeRule(message: "default specimen request needs a value"),
                DefaultSpecimenRequestPayerLengthRule(maxLength: 16),
            ]
        )
    }
}
