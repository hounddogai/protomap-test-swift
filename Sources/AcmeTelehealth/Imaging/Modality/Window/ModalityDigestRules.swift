import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality digest must pass. Check returns its problems, or none.
    protocol ModalityDigestRule {
        func check(_ item: ModalityDigest) -> [String]
    }

    final class ModalityDigestNameLengthRule: ModalityDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityDigest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityDigestUnitLengthRule: ModalityDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityDigest) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityDigestAllowedCodeRule: ModalityDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ModalityDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class ModalityDigestRequiredAllergyRule: ModalityDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityDigest) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityDigestAllergyLengthRule: ModalityDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityDigest) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a modality digest.
    final class ModalityDigestValidator {
        var rules: [any ModalityDigestRule]

        init(rules: [any ModalityDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ModalityDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityDigest]) -> [String: [String]] {
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

    static func defaultModalityDigestValidator() -> ModalityDigestValidator {
        return ModalityDigestValidator(
            rules: [
                ModalityDigestNameLengthRule(maxLength: 64),
                ModalityDigestUnitLengthRule(maxLength: 64),
                ModalityDigestAllowedCodeRule(allowed: ["rolling", "fallback"]),
                ModalityDigestRequiredAllergyRule(message: "modality digest needs an entry"),
                ModalityDigestAllergyLengthRule(maxLength: 16),
            ]
        )
    }
}
