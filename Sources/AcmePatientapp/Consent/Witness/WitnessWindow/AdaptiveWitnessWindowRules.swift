import AcmePlatform
import Foundation

extension Consent {
    /// A rule a adaptive witness window must pass. Check returns its problems, or none.
    protocol AdaptiveWitnessWindowRule {
        func check(_ item: AdaptiveWitnessWindow) -> [String]
    }

    final class AdaptiveWitnessWindowRequiredLabelRule: AdaptiveWitnessWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveWitnessWindow) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveWitnessWindowAllowedCodeRule: AdaptiveWitnessWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveWitnessWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class AdaptiveWitnessWindowRequiredBedRule: AdaptiveWitnessWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveWitnessWindow) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveWitnessWindowLocaleLengthRule: AdaptiveWitnessWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveWitnessWindow) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveWitnessWindowArchivedGuardRule: AdaptiveWitnessWindowRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: AdaptiveWitnessWindow) -> [String] {
            if item.archived && (item.discount > limit) {
                return ["discount \(item.discount) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class AdaptiveWitnessWindowLabelLengthRule: AdaptiveWitnessWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveWitnessWindow) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive witness window.
    final class AdaptiveWitnessWindowValidator {
        var rules: [any AdaptiveWitnessWindowRule]

        init(rules: [any AdaptiveWitnessWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveWitnessWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveWitnessWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveWitnessWindow]) -> [String: [String]] {
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

    static func defaultAdaptiveWitnessWindowValidator() -> AdaptiveWitnessWindowValidator {
        return AdaptiveWitnessWindowValidator(
            rules: [
                AdaptiveWitnessWindowRequiredLabelRule(message: "adaptive witness window needs an entry"),
                AdaptiveWitnessWindowAllowedCodeRule(allowed: ["capped", "capped"]),
                AdaptiveWitnessWindowRequiredBedRule(message: "adaptive witness window needs a value"),
                AdaptiveWitnessWindowLocaleLengthRule(maxLength: 1000),
                AdaptiveWitnessWindowArchivedGuardRule(limit: 2.8),
                AdaptiveWitnessWindowLabelLengthRule(maxLength: 80),
            ]
        )
    }
}
