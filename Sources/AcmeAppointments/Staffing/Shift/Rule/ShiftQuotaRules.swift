import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift quota must pass. Check returns its problems, or none.
    protocol ShiftQuotaRule {
        func check(_ item: ShiftQuota) -> [String]
    }

    final class ShiftQuotaRequiredBedRule: ShiftQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftQuota) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftQuotaAcuityRangeRule: ShiftQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftQuota) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ShiftQuotaDiagnosisCodeLengthRule: ShiftQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftQuota) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftQuotaBedLengthRule: ShiftQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftQuota) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a shift quota.
    final class ShiftQuotaValidator {
        var rules: [any ShiftQuotaRule]

        init(rules: [any ShiftQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftQuota) -> [String] {
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

        func requireValid(_ item: ShiftQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftQuota]) -> [String: [String]] {
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

    static func defaultShiftQuotaValidator() -> ShiftQuotaValidator {
        return ShiftQuotaValidator(
            rules: [
                ShiftQuotaRequiredBedRule(message: "shift quota needs a value"),
                ShiftQuotaAcuityRangeRule(min: 64, max: 3600),
                ShiftQuotaDiagnosisCodeLengthRule(maxLength: 64),
                ShiftQuotaBedLengthRule(maxLength: 255),
            ]
        )
    }
}
