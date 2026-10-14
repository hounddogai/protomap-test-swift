import AcmePlatform
import Foundation

extension Consent {
    /// A rule a seasonal consent form target must pass. Check returns its problems, or none.
    protocol SeasonalConsentFormTargetRule {
        func check(_ item: SeasonalConsentFormTarget) -> [String]
    }

    final class SeasonalConsentFormTargetCodeLengthRule: SeasonalConsentFormTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalConsentFormTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalConsentFormTargetVisibleGuardRule: SeasonalConsentFormTargetRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: SeasonalConsentFormTarget) -> [String] {
            if item.visible && (item.capacity > limit) {
                return ["capacity \(item.capacity) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class SeasonalConsentFormTargetRequiredNameRule: SeasonalConsentFormTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalConsentFormTarget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalConsentFormTargetNameLengthRule: SeasonalConsentFormTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalConsentFormTarget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal consent form target.
    final class SeasonalConsentFormTargetValidator {
        var rules: [any SeasonalConsentFormTargetRule]

        init(rules: [any SeasonalConsentFormTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalConsentFormTarget) -> [String] {
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

        func requireValid(_ item: SeasonalConsentFormTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalConsentFormTarget]) -> [String: [String]] {
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

    static func defaultSeasonalConsentFormTargetValidator() -> SeasonalConsentFormTargetValidator {
        return SeasonalConsentFormTargetValidator(
            rules: [
                SeasonalConsentFormTargetCodeLengthRule(maxLength: 3600),
                SeasonalConsentFormTargetVisibleGuardRule(limit: 64),
                SeasonalConsentFormTargetRequiredNameRule(message: "seasonal consent form target needs a value"),
                SeasonalConsentFormTargetNameLengthRule(maxLength: 255),
            ]
        )
    }
}
