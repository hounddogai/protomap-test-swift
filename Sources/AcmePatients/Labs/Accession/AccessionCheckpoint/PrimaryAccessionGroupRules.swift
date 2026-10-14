import AcmePlatform
import Foundation

extension Labs {
    /// A rule a primary accession group must pass. Check returns its problems, or none.
    protocol PrimaryAccessionGroupRule {
        func check(_ item: PrimaryAccessionGroup) -> [String]
    }

    final class PrimaryAccessionGroupExternalRefLengthRule: PrimaryAccessionGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryAccessionGroup) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryAccessionGroupAllowedCodeRule: PrimaryAccessionGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryAccessionGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class PrimaryAccessionGroupCodeLengthRule: PrimaryAccessionGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryAccessionGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryAccessionGroupRequiredClinicianIDRule: PrimaryAccessionGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryAccessionGroup) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryAccessionGroupClinicianIDLengthRule: PrimaryAccessionGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryAccessionGroup) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryAccessionGroupRequiredCodeRule: PrimaryAccessionGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryAccessionGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary accession group.
    final class PrimaryAccessionGroupValidator {
        var rules: [any PrimaryAccessionGroupRule]

        init(rules: [any PrimaryAccessionGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryAccessionGroup) -> [String] {
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

        func requireValid(_ item: PrimaryAccessionGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryAccessionGroup]) -> [String: [String]] {
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

    static func defaultPrimaryAccessionGroupValidator() -> PrimaryAccessionGroupValidator {
        return PrimaryAccessionGroupValidator(
            rules: [
                PrimaryAccessionGroupExternalRefLengthRule(maxLength: 255),
                PrimaryAccessionGroupAllowedCodeRule(allowed: ["legacy", "pending"]),
                PrimaryAccessionGroupCodeLengthRule(maxLength: 1000),
                PrimaryAccessionGroupRequiredClinicianIDRule(message: "primary accession group needs this field"),
                PrimaryAccessionGroupClinicianIDLengthRule(maxLength: 80),
                PrimaryAccessionGroupRequiredCodeRule(message: "primary accession group needs this field"),
            ]
        )
    }
}
