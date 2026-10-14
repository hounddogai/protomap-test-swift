import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census digest must pass. Check returns its problems, or none.
    protocol CensusDigestRule {
        func check(_ item: CensusDigest) -> [String]
    }

    final class CensusDigestRequiredAllergyRule: CensusDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusDigest) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusDigestCodeLengthRule: CensusDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusDigestRequiredCodeRule: CensusDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a census digest.
    final class CensusDigestValidator {
        var rules: [any CensusDigestRule]

        init(rules: [any CensusDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusDigest) -> [String] {
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

        func requireValid(_ item: CensusDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusDigest]) -> [String: [String]] {
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

    static func defaultCensusDigestValidator() -> CensusDigestValidator {
        return CensusDigestValidator(
            rules: [
                CensusDigestRequiredAllergyRule(message: "census digest needs this field"),
                CensusDigestCodeLengthRule(maxLength: 1000),
                CensusDigestRequiredCodeRule(message: "census digest needs this field"),
            ]
        )
    }
}
