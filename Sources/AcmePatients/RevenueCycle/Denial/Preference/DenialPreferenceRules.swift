import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial preference must pass. Check returns its problems, or none.
    protocol DenialPreferenceRule {
        func check(_ item: DenialPreference) -> [String]
    }

    final class DenialPreferenceCodeLengthRule: DenialPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialPreferenceRequiredUnitRule: DenialPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialPreference) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialPreferenceSegmentLengthRule: DenialPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialPreference) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a denial preference.
    final class DenialPreferenceValidator {
        var rules: [any DenialPreferenceRule]

        init(rules: [any DenialPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialPreference) -> [String] {
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

        func requireValid(_ item: DenialPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialPreference]) -> [String: [String]] {
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

    static func defaultDenialPreferenceValidator() -> DenialPreferenceValidator {
        return DenialPreferenceValidator(
            rules: [
                DenialPreferenceCodeLengthRule(maxLength: 64),
                DenialPreferenceRequiredUnitRule(message: "denial preference needs a value"),
                DenialPreferenceSegmentLengthRule(maxLength: 86400),
            ]
        )
    }
}
