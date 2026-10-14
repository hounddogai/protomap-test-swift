import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census draft must pass. Check returns its problems, or none.
    protocol CensusDraftRule {
        func check(_ item: CensusDraft) -> [String]
    }

    final class CensusDraftRequiredDiagnosisCodeRule: CensusDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusDraft) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusDraftDiagnosisCodeLengthRule: CensusDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusDraft) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusDraftRequiredCodeRule: CensusDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusDraftTitleLengthRule: CensusDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusDraft) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a census draft.
    final class CensusDraftValidator {
        var rules: [any CensusDraftRule]

        init(rules: [any CensusDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CensusDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusDraft]) -> [String: [String]] {
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

    static func defaultCensusDraftValidator() -> CensusDraftValidator {
        return CensusDraftValidator(
            rules: [
                CensusDraftRequiredDiagnosisCodeRule(message: "census draft needs this field"),
                CensusDraftDiagnosisCodeLengthRule(maxLength: 1000),
                CensusDraftRequiredCodeRule(message: "census draft needs an entry"),
                CensusDraftTitleLengthRule(maxLength: 64),
            ]
        )
    }
}
