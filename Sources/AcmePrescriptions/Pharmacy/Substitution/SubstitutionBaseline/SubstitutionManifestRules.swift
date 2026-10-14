import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution manifest must pass. Check returns its problems, or none.
    protocol SubstitutionManifestRule {
        func check(_ item: SubstitutionManifest) -> [String]
    }

    final class SubstitutionManifestTitleLengthRule: SubstitutionManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionManifest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionManifestRequiredLabelRule: SubstitutionManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionManifest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionManifestRequiredCodeRule: SubstitutionManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionManifestRequiredOwnerIDRule: SubstitutionManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionManifest) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionManifestStartsAtRangeRule: SubstitutionManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionManifest) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a substitution manifest.
    final class SubstitutionManifestValidator {
        var rules: [any SubstitutionManifestRule]

        init(rules: [any SubstitutionManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionManifest) -> [String] {
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

        func requireValid(_ item: SubstitutionManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionManifest]) -> [String: [String]] {
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

    static func defaultSubstitutionManifestValidator() -> SubstitutionManifestValidator {
        return SubstitutionManifestValidator(
            rules: [
                SubstitutionManifestTitleLengthRule(maxLength: 16),
                SubstitutionManifestRequiredLabelRule(message: "substitution manifest needs this field"),
                SubstitutionManifestRequiredCodeRule(message: "substitution manifest needs an entry"),
                SubstitutionManifestRequiredOwnerIDRule(message: "substitution manifest needs an entry"),
                SubstitutionManifestStartsAtRangeRule(min: 32, max: 86400),
            ]
        )
    }
}
