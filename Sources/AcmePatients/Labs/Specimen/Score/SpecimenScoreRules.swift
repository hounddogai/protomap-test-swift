import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen score must pass. Check returns its problems, or none.
    protocol SpecimenScoreRule {
        func check(_ item: SpecimenScore) -> [String]
    }

    final class SpecimenScoreRequiredNameRule: SpecimenScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenScore) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenScoreExternalRefLengthRule: SpecimenScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenScore) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenScoreRequiredCodeRule: SpecimenScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenScoreExpiresAtRangeRule: SpecimenScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenScore) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SpecimenScoreWindowDaysRangeRule: SpecimenScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenScore) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SpecimenScoreNameLengthRule: SpecimenScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenScore) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a specimen score.
    final class SpecimenScoreValidator {
        var rules: [any SpecimenScoreRule]

        init(rules: [any SpecimenScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenScore) -> [String] {
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

        func requireValid(_ item: SpecimenScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenScore]) -> [String: [String]] {
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

    static func defaultSpecimenScoreValidator() -> SpecimenScoreValidator {
        return SpecimenScoreValidator(
            rules: [
                SpecimenScoreRequiredNameRule(message: "specimen score needs an entry"),
                SpecimenScoreExternalRefLengthRule(maxLength: 3600),
                SpecimenScoreRequiredCodeRule(message: "specimen score needs this field"),
                SpecimenScoreExpiresAtRangeRule(min: 255, max: 3600),
                SpecimenScoreWindowDaysRangeRule(min: 255, max: 1000),
                SpecimenScoreNameLengthRule(maxLength: 64),
            ]
        )
    }
}
