import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census template must pass. Check returns its problems, or none.
    protocol CensusTemplateRule {
        func check(_ item: CensusTemplate) -> [String]
    }

    final class CensusTemplateSummaryLengthRule: CensusTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusTemplate) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusTemplateNameLengthRule: CensusTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusTemplate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusTemplateCodeLengthRule: CensusTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a census template.
    final class CensusTemplateValidator {
        var rules: [any CensusTemplateRule]

        init(rules: [any CensusTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CensusTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusTemplate]) -> [String: [String]] {
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

    static func defaultCensusTemplateValidator() -> CensusTemplateValidator {
        return CensusTemplateValidator(
            rules: [
                CensusTemplateSummaryLengthRule(maxLength: 80),
                CensusTemplateNameLengthRule(maxLength: 120),
                CensusTemplateCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
