import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession digest must pass. Check returns its problems, or none.
    protocol AccessionDigestRule {
        func check(_ item: AccessionDigest) -> [String]
    }

    final class AccessionDigestRequiredDiagnosisCodeRule: AccessionDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionDigest) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionDigestQuantityRangeRule: AccessionDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionDigest) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AccessionDigestTitleLengthRule: AccessionDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionDigest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionDigestArchivedGuardRule: AccessionDigestRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: AccessionDigest) -> [String] {
            if item.archived && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a accession digest.
    final class AccessionDigestValidator {
        var rules: [any AccessionDigestRule]

        init(rules: [any AccessionDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionDigest) -> [String] {
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

        func requireValid(_ item: AccessionDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionDigest]) -> [String: [String]] {
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

    static func defaultAccessionDigestValidator() -> AccessionDigestValidator {
        return AccessionDigestValidator(
            rules: [
                AccessionDigestRequiredDiagnosisCodeRule(message: "accession digest needs this field"),
                AccessionDigestQuantityRangeRule(min: 32, max: 86400),
                AccessionDigestTitleLengthRule(maxLength: 64),
                AccessionDigestArchivedGuardRule(limit: 120),
            ]
        )
    }
}
