import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a manual formulary digest must pass. Check returns its problems, or none.
    protocol ManualFormularyDigestRule {
        func check(_ item: ManualFormularyDigest) -> [String]
    }

    final class ManualFormularyDigestLabelLengthRule: ManualFormularyDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualFormularyDigest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualFormularyDigestProcedureCodeLengthRule: ManualFormularyDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualFormularyDigest) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualFormularyDigestVisitMinutesRangeRule: ManualFormularyDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualFormularyDigest) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a manual formulary digest.
    final class ManualFormularyDigestValidator {
        var rules: [any ManualFormularyDigestRule]

        init(rules: [any ManualFormularyDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualFormularyDigest) -> [String] {
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

        func requireValid(_ item: ManualFormularyDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualFormularyDigest]) -> [String: [String]] {
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

    static func defaultManualFormularyDigestValidator() -> ManualFormularyDigestValidator {
        return ManualFormularyDigestValidator(
            rules: [
                ManualFormularyDigestLabelLengthRule(maxLength: 1000),
                ManualFormularyDigestProcedureCodeLengthRule(maxLength: 86400),
                ManualFormularyDigestVisitMinutesRangeRule(min: 120, max: 120),
            ]
        )
    }
}
