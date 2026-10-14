import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a regional formulary cycle must pass. Check returns its problems, or none.
    protocol RegionalFormularyCycleRule {
        func check(_ item: RegionalFormularyCycle) -> [String]
    }

    final class RegionalFormularyCycleAllowedEncounterIDRule: RegionalFormularyCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalFormularyCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.encounterID)) {
                return ["encounter id \(item.encounterID) is expired"]
            }
            return []
        }
    }

    final class RegionalFormularyCycleNameLengthRule: RegionalFormularyCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalFormularyCycle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalFormularyCycleRequiredCodeRule: RegionalFormularyCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalFormularyCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalFormularyCycleCodeLengthRule: RegionalFormularyCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalFormularyCycle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalFormularyCycleRequiredContactEmailRule: RegionalFormularyCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalFormularyCycle) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalFormularyCycleCodePrefixRule: RegionalFormularyCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalFormularyCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional formulary cycle.
    final class RegionalFormularyCycleValidator {
        var rules: [any RegionalFormularyCycleRule]

        init(rules: [any RegionalFormularyCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalFormularyCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalFormularyCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalFormularyCycle]) -> [String: [String]] {
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

    static func defaultRegionalFormularyCycleValidator() -> RegionalFormularyCycleValidator {
        return RegionalFormularyCycleValidator(
            rules: [
                RegionalFormularyCycleAllowedEncounterIDRule(allowed: ["pending"]),
                RegionalFormularyCycleNameLengthRule(maxLength: 16),
                RegionalFormularyCycleRequiredCodeRule(message: "regional formulary cycle needs a value"),
                RegionalFormularyCycleCodeLengthRule(maxLength: 16),
                RegionalFormularyCycleRequiredContactEmailRule(message: "regional formulary cycle needs this field"),
                RegionalFormularyCycleCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
