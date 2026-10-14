import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a default charge request must pass. Check returns its problems, or none.
    protocol DefaultChargeRequestRule {
        func check(_ item: DefaultChargeRequest) -> [String]
    }

    final class DefaultChargeRequestPhoneLengthRule: DefaultChargeRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultChargeRequest) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultChargeRequestRequiredPhoneRule: DefaultChargeRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultChargeRequest) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultChargeRequestCountryLengthRule: DefaultChargeRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultChargeRequest) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultChargeRequestNameLengthRule: DefaultChargeRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultChargeRequest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultChargeRequestRequiredCountryRule: DefaultChargeRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultChargeRequest) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default charge request.
    final class DefaultChargeRequestValidator {
        var rules: [any DefaultChargeRequestRule]

        init(rules: [any DefaultChargeRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultChargeRequest) -> [String] {
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

        func requireValid(_ item: DefaultChargeRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultChargeRequest]) -> [String: [String]] {
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

    static func defaultDefaultChargeRequestValidator() -> DefaultChargeRequestValidator {
        return DefaultChargeRequestValidator(
            rules: [
                DefaultChargeRequestPhoneLengthRule(maxLength: 16),
                DefaultChargeRequestRequiredPhoneRule(message: "default charge request needs an entry"),
                DefaultChargeRequestCountryLengthRule(maxLength: 16),
                DefaultChargeRequestNameLengthRule(maxLength: 32),
                DefaultChargeRequestRequiredCountryRule(message: "default charge request needs this field"),
            ]
        )
    }
}
