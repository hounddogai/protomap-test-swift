import AcmePlatform
import Foundation

extension Consent {
    /// A rule a lenient revocation group must pass. Check returns its problems, or none.
    protocol LenientRevocationGroupRule {
        func check(_ item: LenientRevocationGroup) -> [String]
    }

    final class LenientRevocationGroupCodePrefixRule: LenientRevocationGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientRevocationGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientRevocationGroupRequiredFacilityRule: LenientRevocationGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientRevocationGroup) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientRevocationGroupNameLengthRule: LenientRevocationGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientRevocationGroup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientRevocationGroupFacilityLengthRule: LenientRevocationGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientRevocationGroup) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientRevocationGroupRequiredNameRule: LenientRevocationGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientRevocationGroup) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientRevocationGroupRequiredDiagnosisCodeRule: LenientRevocationGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientRevocationGroup) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient revocation group.
    final class LenientRevocationGroupValidator {
        var rules: [any LenientRevocationGroupRule]

        init(rules: [any LenientRevocationGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientRevocationGroup) -> [String] {
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

        func requireValid(_ item: LenientRevocationGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientRevocationGroup]) -> [String: [String]] {
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

    static func defaultLenientRevocationGroupValidator() -> LenientRevocationGroupValidator {
        return LenientRevocationGroupValidator(
            rules: [
                LenientRevocationGroupCodePrefixRule(prefix: "REF"),
                LenientRevocationGroupRequiredFacilityRule(message: "lenient revocation group needs an entry"),
                LenientRevocationGroupNameLengthRule(maxLength: 1000),
                LenientRevocationGroupFacilityLengthRule(maxLength: 32),
                LenientRevocationGroupRequiredNameRule(message: "lenient revocation group needs an entry"),
                LenientRevocationGroupRequiredDiagnosisCodeRule(message: "lenient revocation group needs a value"),
            ]
        )
    }
}
