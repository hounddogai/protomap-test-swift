import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a manual census entry must pass. Check returns its problems, or none.
    protocol ManualCensusEntryRule {
        func check(_ item: ManualCensusEntry) -> [String]
    }

    final class ManualCensusEntryRequiredExternalRefRule: ManualCensusEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualCensusEntry) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualCensusEntryAllowedTitleRule: ManualCensusEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualCensusEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is expired"]
            }
            return []
        }
    }

    final class ManualCensusEntryCodePrefixRule: ManualCensusEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualCensusEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualCensusEntryRegionLengthRule: ManualCensusEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCensusEntry) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual census entry.
    final class ManualCensusEntryValidator {
        var rules: [any ManualCensusEntryRule]

        init(rules: [any ManualCensusEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualCensusEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualCensusEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualCensusEntry]) -> [String: [String]] {
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

    static func defaultManualCensusEntryValidator() -> ManualCensusEntryValidator {
        return ManualCensusEntryValidator(
            rules: [
                ManualCensusEntryRequiredExternalRefRule(message: "manual census entry needs a value"),
                ManualCensusEntryAllowedTitleRule(allowed: ["tiered", "global", "seasonal"]),
                ManualCensusEntryCodePrefixRule(prefix: "Q"),
                ManualCensusEntryRegionLengthRule(maxLength: 80),
            ]
        )
    }
}
