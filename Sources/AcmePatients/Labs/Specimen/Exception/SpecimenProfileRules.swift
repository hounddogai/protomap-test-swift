import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen profile must pass. Check returns its problems, or none.
    protocol SpecimenProfileRule {
        func check(_ item: SpecimenProfile) -> [String]
    }

    final class SpecimenProfileRequiredNameRule: SpecimenProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenProfile) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenProfileRequiredPayerRule: SpecimenProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenProfile) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenProfileWardLengthRule: SpecimenProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenProfile) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a specimen profile.
    final class SpecimenProfileValidator {
        var rules: [any SpecimenProfileRule]

        init(rules: [any SpecimenProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenProfile) -> [String] {
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

        func requireValid(_ item: SpecimenProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenProfile]) -> [String: [String]] {
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

    static func defaultSpecimenProfileValidator() -> SpecimenProfileValidator {
        return SpecimenProfileValidator(
            rules: [
                SpecimenProfileRequiredNameRule(message: "specimen profile needs this field"),
                SpecimenProfileRequiredPayerRule(message: "specimen profile needs a value"),
                SpecimenProfileWardLengthRule(maxLength: 64),
            ]
        )
    }
}
