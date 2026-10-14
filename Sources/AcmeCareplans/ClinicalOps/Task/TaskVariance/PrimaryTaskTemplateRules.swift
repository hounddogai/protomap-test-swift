import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a primary task template must pass. Check returns its problems, or none.
    protocol PrimaryTaskTemplateRule {
        func check(_ item: PrimaryTaskTemplate) -> [String]
    }

    final class PrimaryTaskTemplateCodePrefixRule: PrimaryTaskTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryTaskTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryTaskTemplateAllowedDiagnosisCodeRule: PrimaryTaskTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryTaskTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is not allowed"]
            }
            return []
        }
    }

    final class PrimaryTaskTemplateNameLengthRule: PrimaryTaskTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryTaskTemplate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryTaskTemplateCodeLengthRule: PrimaryTaskTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryTaskTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryTaskTemplateRequiredCodeRule: PrimaryTaskTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryTaskTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryTaskTemplateChecksumLengthRule: PrimaryTaskTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryTaskTemplate) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary task template.
    final class PrimaryTaskTemplateValidator {
        var rules: [any PrimaryTaskTemplateRule]

        init(rules: [any PrimaryTaskTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryTaskTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryTaskTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryTaskTemplate]) -> [String: [String]] {
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

    static func defaultPrimaryTaskTemplateValidator() -> PrimaryTaskTemplateValidator {
        return PrimaryTaskTemplateValidator(
            rules: [
                PrimaryTaskTemplateCodePrefixRule(prefix: "Q"),
                PrimaryTaskTemplateAllowedDiagnosisCodeRule(allowed: ["batched"]),
                PrimaryTaskTemplateNameLengthRule(maxLength: 86400),
                PrimaryTaskTemplateCodeLengthRule(maxLength: 86400),
                PrimaryTaskTemplateRequiredCodeRule(message: "primary task template needs this field"),
                PrimaryTaskTemplateChecksumLengthRule(maxLength: 32),
            ]
        )
    }
}
