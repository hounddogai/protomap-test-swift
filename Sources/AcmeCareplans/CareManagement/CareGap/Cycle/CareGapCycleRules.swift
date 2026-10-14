import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap cycle must pass. Check returns its problems, or none.
    protocol CareGapCycleRule {
        func check(_ item: CareGapCycle) -> [String]
    }

    final class CareGapCycleRequiredTitleRule: CareGapCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapCycle) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapCycleRequiredDiagnosisCodeRule: CareGapCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapCycle) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapCycleDiagnosisCodeLengthRule: CareGapCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapCycle) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care gap cycle.
    final class CareGapCycleValidator {
        var rules: [any CareGapCycleRule]

        init(rules: [any CareGapCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapCycle) -> [String] {
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

        func requireValid(_ item: CareGapCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapCycle]) -> [String: [String]] {
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

    static func defaultCareGapCycleValidator() -> CareGapCycleValidator {
        return CareGapCycleValidator(
            rules: [
                CareGapCycleRequiredTitleRule(message: "care gap cycle needs an entry"),
                CareGapCycleRequiredDiagnosisCodeRule(message: "care gap cycle needs a value"),
                CareGapCycleDiagnosisCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
