import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a primary discharge plan adjustment must pass. Check returns its problems, or none.
    protocol PrimaryDischargePlanAdjustmentRule {
        func check(_ item: PrimaryDischargePlanAdjustment) -> [String]
    }

    final class PrimaryDischargePlanAdjustmentRequiredTitleRule: PrimaryDischargePlanAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryDischargePlanAdjustment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryDischargePlanAdjustmentCodePrefixRule: PrimaryDischargePlanAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryDischargePlanAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryDischargePlanAdjustmentDurationMinutesRangeRule: PrimaryDischargePlanAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryDischargePlanAdjustment) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryDischargePlanAdjustmentRequiredDiagnosisCodeRule: PrimaryDischargePlanAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryDischargePlanAdjustment) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryDischargePlanAdjustmentDiagnosisCodeLengthRule: PrimaryDischargePlanAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryDischargePlanAdjustment) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary discharge plan adjustment.
    final class PrimaryDischargePlanAdjustmentValidator {
        var rules: [any PrimaryDischargePlanAdjustmentRule]

        init(rules: [any PrimaryDischargePlanAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryDischargePlanAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryDischargePlanAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryDischargePlanAdjustment]) -> [String: [String]] {
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

    static func defaultPrimaryDischargePlanAdjustmentValidator() -> PrimaryDischargePlanAdjustmentValidator {
        return PrimaryDischargePlanAdjustmentValidator(
            rules: [
                PrimaryDischargePlanAdjustmentRequiredTitleRule(
                    message: "primary discharge plan adjustment needs this field"
                ),
                PrimaryDischargePlanAdjustmentCodePrefixRule(prefix: "ACM"),
                PrimaryDischargePlanAdjustmentDurationMinutesRangeRule(min: 64, max: 3600),
                PrimaryDischargePlanAdjustmentRequiredDiagnosisCodeRule(
                    message: "primary discharge plan adjustment needs a value"
                ),
                PrimaryDischargePlanAdjustmentDiagnosisCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
