import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding profile must pass. Check returns its problems, or none.
    protocol RoundingProfileRule {
        func check(_ item: RoundingProfile) -> [String]
    }

    final class RoundingProfileNameLengthRule: RoundingProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingProfile) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingProfileCountryLengthRule: RoundingProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingProfile) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingProfileRequiredNameRule: RoundingProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingProfile) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingProfileRequiredCodeRule: RoundingProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingProfileRequiredChannelRule: RoundingProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingProfile) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingProfileAllowedCountryRule: RoundingProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RoundingProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a rounding profile.
    final class RoundingProfileValidator {
        var rules: [any RoundingProfileRule]

        init(rules: [any RoundingProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RoundingProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingProfile]) -> [String: [String]] {
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

    static func defaultRoundingProfileValidator() -> RoundingProfileValidator {
        return RoundingProfileValidator(
            rules: [
                RoundingProfileNameLengthRule(maxLength: 3600),
                RoundingProfileCountryLengthRule(maxLength: 86400),
                RoundingProfileRequiredNameRule(message: "rounding profile needs this field"),
                RoundingProfileRequiredCodeRule(message: "rounding profile needs an entry"),
                RoundingProfileRequiredChannelRule(message: "rounding profile needs a value"),
                RoundingProfileAllowedCountryRule(allowed: []),
            ]
        )
    }
}
