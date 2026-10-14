import AcmePlatform
import Foundation

extension Labs {
    /// A rule a legacy accession baseline must pass. Check returns its problems, or none.
    protocol LegacyAccessionBaselineRule {
        func check(_ item: LegacyAccessionBaseline) -> [String]
    }

    final class LegacyAccessionBaselineCodeLengthRule: LegacyAccessionBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyAccessionBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyAccessionBaselineRequiredCodeRule: LegacyAccessionBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAccessionBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyAccessionBaselineRequiredChecksumRule: LegacyAccessionBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAccessionBaseline) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyAccessionBaselineAllowedUnitRule: LegacyAccessionBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyAccessionBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy accession baseline.
    final class LegacyAccessionBaselineValidator {
        var rules: [any LegacyAccessionBaselineRule]

        init(rules: [any LegacyAccessionBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyAccessionBaseline) -> [String] {
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

        func requireValid(_ item: LegacyAccessionBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyAccessionBaseline]) -> [String: [String]] {
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

    static func defaultLegacyAccessionBaselineValidator() -> LegacyAccessionBaselineValidator {
        return LegacyAccessionBaselineValidator(
            rules: [
                LegacyAccessionBaselineCodeLengthRule(maxLength: 32),
                LegacyAccessionBaselineRequiredCodeRule(message: "legacy accession baseline needs a value"),
                LegacyAccessionBaselineRequiredChecksumRule(message: "legacy accession baseline needs a value"),
                LegacyAccessionBaselineAllowedUnitRule(allowed: []),
            ]
        )
    }
}
