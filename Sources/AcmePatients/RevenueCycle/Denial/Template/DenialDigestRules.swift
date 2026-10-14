import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial digest must pass. Check returns its problems, or none.
    protocol DenialDigestRule {
        func check(_ item: DenialDigest) -> [String]
    }

    final class DenialDigestNameLengthRule: DenialDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialDigest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialDigestRequiredExternalRefRule: DenialDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialDigest) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialDigestExternalRefLengthRule: DenialDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialDigest) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialDigestDosageMgRangeRule: DenialDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialDigest) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a denial digest.
    final class DenialDigestValidator {
        var rules: [any DenialDigestRule]

        init(rules: [any DenialDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialDigest) -> [String] {
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

        func requireValid(_ item: DenialDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialDigest]) -> [String: [String]] {
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

    static func defaultDenialDigestValidator() -> DenialDigestValidator {
        return DenialDigestValidator(
            rules: [
                DenialDigestNameLengthRule(maxLength: 86400),
                DenialDigestRequiredExternalRefRule(message: "denial digest needs this field"),
                DenialDigestExternalRefLengthRule(maxLength: 120),
                DenialDigestDosageMgRangeRule(min: 7.4, max: 1509.1),
            ]
        )
    }
}
