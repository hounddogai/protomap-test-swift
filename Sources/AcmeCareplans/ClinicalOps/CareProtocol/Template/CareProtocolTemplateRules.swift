import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol template must pass. Check returns its problems, or none.
    protocol CareProtocolTemplateRule {
        func check(_ item: CareProtocolTemplate) -> [String]
    }

    final class CareProtocolTemplateVersionRangeRule: CareProtocolTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolTemplate) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareProtocolTemplateRequiredCodeRule: CareProtocolTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolTemplateCodeLengthRule: CareProtocolTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolTemplateChecksumLengthRule: CareProtocolTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolTemplate) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolTemplateNameLengthRule: CareProtocolTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolTemplate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol template.
    final class CareProtocolTemplateValidator {
        var rules: [any CareProtocolTemplateRule]

        init(rules: [any CareProtocolTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolTemplate) -> [String] {
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

        func requireValid(_ item: CareProtocolTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolTemplate]) -> [String: [String]] {
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

    static func defaultCareProtocolTemplateValidator() -> CareProtocolTemplateValidator {
        return CareProtocolTemplateValidator(
            rules: [
                CareProtocolTemplateVersionRangeRule(min: 32, max: 3600),
                CareProtocolTemplateRequiredCodeRule(message: "care protocol template needs this field"),
                CareProtocolTemplateCodeLengthRule(maxLength: 3600),
                CareProtocolTemplateChecksumLengthRule(maxLength: 80),
                CareProtocolTemplateNameLengthRule(maxLength: 80),
            ]
        )
    }
}
