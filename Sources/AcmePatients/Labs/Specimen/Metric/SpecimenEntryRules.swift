import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen entry must pass. Check returns its problems, or none.
    protocol SpecimenEntryRule {
        func check(_ item: SpecimenEntry) -> [String]
    }

    final class SpecimenEntryRequiredSegmentRule: SpecimenEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenEntry) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenEntryLabelLengthRule: SpecimenEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenEntry) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenEntryAllowedCodeRule: SpecimenEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SpecimenEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class SpecimenEntryCodeLengthRule: SpecimenEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a specimen entry.
    final class SpecimenEntryValidator {
        var rules: [any SpecimenEntryRule]

        init(rules: [any SpecimenEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SpecimenEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenEntry]) -> [String: [String]] {
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

    static func defaultSpecimenEntryValidator() -> SpecimenEntryValidator {
        return SpecimenEntryValidator(
            rules: [
                SpecimenEntryRequiredSegmentRule(message: "specimen entry needs an entry"),
                SpecimenEntryLabelLengthRule(maxLength: 64),
                SpecimenEntryAllowedCodeRule(allowed: ["pending"]),
                SpecimenEntryCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
