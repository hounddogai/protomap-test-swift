import AcmePlatform
import Foundation

extension Consent {
    /// A rule a adaptive witness group must pass. Check returns its problems, or none.
    protocol AdaptiveWitnessGroupRule {
        func check(_ item: AdaptiveWitnessGroup) -> [String]
    }

    final class AdaptiveWitnessGroupRequiredChannelRule: AdaptiveWitnessGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveWitnessGroup) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveWitnessGroupChannelLengthRule: AdaptiveWitnessGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveWitnessGroup) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveWitnessGroupCodeLengthRule: AdaptiveWitnessGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveWitnessGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveWitnessGroupRequiredCodeRule: AdaptiveWitnessGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveWitnessGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveWitnessGroupRequiredTitleRule: AdaptiveWitnessGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveWitnessGroup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive witness group.
    final class AdaptiveWitnessGroupValidator {
        var rules: [any AdaptiveWitnessGroupRule]

        init(rules: [any AdaptiveWitnessGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveWitnessGroup) -> [String] {
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

        func requireValid(_ item: AdaptiveWitnessGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveWitnessGroup]) -> [String: [String]] {
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

    static func defaultAdaptiveWitnessGroupValidator() -> AdaptiveWitnessGroupValidator {
        return AdaptiveWitnessGroupValidator(
            rules: [
                AdaptiveWitnessGroupRequiredChannelRule(message: "adaptive witness group needs this field"),
                AdaptiveWitnessGroupChannelLengthRule(maxLength: 255),
                AdaptiveWitnessGroupCodeLengthRule(maxLength: 86400),
                AdaptiveWitnessGroupRequiredCodeRule(message: "adaptive witness group needs an entry"),
                AdaptiveWitnessGroupRequiredTitleRule(message: "adaptive witness group needs an entry"),
            ]
        )
    }
}
