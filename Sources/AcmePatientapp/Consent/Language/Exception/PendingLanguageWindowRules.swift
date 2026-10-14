import AcmePlatform
import Foundation

extension Consent {
    /// A rule a pending language window must pass. Check returns its problems, or none.
    protocol PendingLanguageWindowRule {
        func check(_ item: PendingLanguageWindow) -> [String]
    }

    final class PendingLanguageWindowNameLengthRule: PendingLanguageWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingLanguageWindow) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingLanguageWindowRequiredLocaleRule: PendingLanguageWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingLanguageWindow) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingLanguageWindowAllowedRegionRule: PendingLanguageWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingLanguageWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.region)) {
                return ["region \(item.region) is blocked"]
            }
            return []
        }
    }

    final class PendingLanguageWindowAllergyLengthRule: PendingLanguageWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingLanguageWindow) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingLanguageWindowRequiredAllergyRule: PendingLanguageWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingLanguageWindow) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingLanguageWindowRequiredCodeRule: PendingLanguageWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingLanguageWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending language window.
    final class PendingLanguageWindowValidator {
        var rules: [any PendingLanguageWindowRule]

        init(rules: [any PendingLanguageWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingLanguageWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingLanguageWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingLanguageWindow]) -> [String: [String]] {
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

    static func defaultPendingLanguageWindowValidator() -> PendingLanguageWindowValidator {
        return PendingLanguageWindowValidator(
            rules: [
                PendingLanguageWindowNameLengthRule(maxLength: 255),
                PendingLanguageWindowRequiredLocaleRule(message: "pending language window needs an entry"),
                PendingLanguageWindowAllowedRegionRule(allowed: ["lenient", "legacy"]),
                PendingLanguageWindowAllergyLengthRule(maxLength: 80),
                PendingLanguageWindowRequiredAllergyRule(message: "pending language window needs a value"),
                PendingLanguageWindowRequiredCodeRule(message: "pending language window needs this field"),
            ]
        )
    }
}
