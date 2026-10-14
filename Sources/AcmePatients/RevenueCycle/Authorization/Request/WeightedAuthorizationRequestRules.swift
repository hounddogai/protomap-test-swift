import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a weighted authorization request must pass. Check returns its problems, or none.
    protocol WeightedAuthorizationRequestRule {
        func check(_ item: WeightedAuthorizationRequest) -> [String]
    }

    final class WeightedAuthorizationRequestCategoryLengthRule: WeightedAuthorizationRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedAuthorizationRequest) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedAuthorizationRequestRequiredEncounterIDRule: WeightedAuthorizationRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedAuthorizationRequest) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedAuthorizationRequestAllowedCodeRule: WeightedAuthorizationRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedAuthorizationRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class WeightedAuthorizationRequestTitleLengthRule: WeightedAuthorizationRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedAuthorizationRequest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedAuthorizationRequestRequiredCodeRule: WeightedAuthorizationRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedAuthorizationRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedAuthorizationRequestCodeLengthRule: WeightedAuthorizationRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedAuthorizationRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted authorization request.
    final class WeightedAuthorizationRequestValidator {
        var rules: [any WeightedAuthorizationRequestRule]

        init(rules: [any WeightedAuthorizationRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedAuthorizationRequest) -> [String] {
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

        func requireValid(_ item: WeightedAuthorizationRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedAuthorizationRequest]) -> [String: [String]] {
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

    static func defaultWeightedAuthorizationRequestValidator() -> WeightedAuthorizationRequestValidator {
        return WeightedAuthorizationRequestValidator(
            rules: [
                WeightedAuthorizationRequestCategoryLengthRule(maxLength: 32),
                WeightedAuthorizationRequestRequiredEncounterIDRule(
                    message: "weighted authorization request needs a value"
                ),
                WeightedAuthorizationRequestAllowedCodeRule(allowed: ["primary"]),
                WeightedAuthorizationRequestTitleLengthRule(maxLength: 16),
                WeightedAuthorizationRequestRequiredCodeRule(message: "weighted authorization request needs a value"),
                WeightedAuthorizationRequestCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
