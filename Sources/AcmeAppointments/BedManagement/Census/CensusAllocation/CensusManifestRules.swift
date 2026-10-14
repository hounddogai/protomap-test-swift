import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census manifest must pass. Check returns its problems, or none.
    protocol CensusManifestRule {
        func check(_ item: CensusManifest) -> [String]
    }

    final class CensusManifestRequiredNameRule: CensusManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusManifest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusManifestCountryLengthRule: CensusManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusManifest) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusManifestNameLengthRule: CensusManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusManifest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a census manifest.
    final class CensusManifestValidator {
        var rules: [any CensusManifestRule]

        init(rules: [any CensusManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusManifest) -> [String] {
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

        func requireValid(_ item: CensusManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusManifest]) -> [String: [String]] {
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

    static func defaultCensusManifestValidator() -> CensusManifestValidator {
        return CensusManifestValidator(
            rules: [
                CensusManifestRequiredNameRule(message: "census manifest needs an entry"),
                CensusManifestCountryLengthRule(maxLength: 86400),
                CensusManifestNameLengthRule(maxLength: 120),
            ]
        )
    }
}
