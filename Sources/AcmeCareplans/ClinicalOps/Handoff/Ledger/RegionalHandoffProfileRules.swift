import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a regional handoff profile must pass. Check returns its problems, or none.
    protocol RegionalHandoffProfileRule {
        func check(_ item: RegionalHandoffProfile) -> [String]
    }

    final class RegionalHandoffProfileCodePrefixRule: RegionalHandoffProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalHandoffProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalHandoffProfileOwnerIDLengthRule: RegionalHandoffProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalHandoffProfile) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalHandoffProfileEncounterIDLengthRule: RegionalHandoffProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalHandoffProfile) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalHandoffProfileRequiredEncounterIDRule: RegionalHandoffProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalHandoffProfile) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalHandoffProfileCodeLengthRule: RegionalHandoffProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalHandoffProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalHandoffProfileRequiredCodeRule: RegionalHandoffProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalHandoffProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional handoff profile.
    final class RegionalHandoffProfileValidator {
        var rules: [any RegionalHandoffProfileRule]

        init(rules: [any RegionalHandoffProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalHandoffProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalHandoffProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalHandoffProfile]) -> [String: [String]] {
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

    static func defaultRegionalHandoffProfileValidator() -> RegionalHandoffProfileValidator {
        return RegionalHandoffProfileValidator(
            rules: [
                RegionalHandoffProfileCodePrefixRule(prefix: "OPS"),
                RegionalHandoffProfileOwnerIDLengthRule(maxLength: 16),
                RegionalHandoffProfileEncounterIDLengthRule(maxLength: 80),
                RegionalHandoffProfileRequiredEncounterIDRule(message: "regional handoff profile needs this field"),
                RegionalHandoffProfileCodeLengthRule(maxLength: 1000),
                RegionalHandoffProfileRequiredCodeRule(message: "regional handoff profile needs a value"),
            ]
        )
    }
}
