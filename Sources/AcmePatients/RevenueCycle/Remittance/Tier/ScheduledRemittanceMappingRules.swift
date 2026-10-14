import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a scheduled remittance mapping must pass. Check returns its problems, or none.
    protocol ScheduledRemittanceMappingRule {
        func check(_ item: ScheduledRemittanceMapping) -> [String]
    }

    final class ScheduledRemittanceMappingClinicianIDLengthRule: ScheduledRemittanceMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledRemittanceMapping) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledRemittanceMappingRequiredNameRule: ScheduledRemittanceMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledRemittanceMapping) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledRemittanceMappingBatchSizeRangeRule: ScheduledRemittanceMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledRemittanceMapping) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledRemittanceMappingCodePrefixRule: ScheduledRemittanceMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledRemittanceMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledRemittanceMappingMinimumRangeRule: ScheduledRemittanceMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledRemittanceMapping) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledRemittanceMappingRequiredClinicianIDRule: ScheduledRemittanceMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledRemittanceMapping) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled remittance mapping.
    final class ScheduledRemittanceMappingValidator {
        var rules: [any ScheduledRemittanceMappingRule]

        init(rules: [any ScheduledRemittanceMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledRemittanceMapping) -> [String] {
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

        func requireValid(_ item: ScheduledRemittanceMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledRemittanceMapping]) -> [String: [String]] {
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

    static func defaultScheduledRemittanceMappingValidator() -> ScheduledRemittanceMappingValidator {
        return ScheduledRemittanceMappingValidator(
            rules: [
                ScheduledRemittanceMappingClinicianIDLengthRule(maxLength: 3600),
                ScheduledRemittanceMappingRequiredNameRule(message: "scheduled remittance mapping needs an entry"),
                ScheduledRemittanceMappingBatchSizeRangeRule(min: 1000, max: 3600),
                ScheduledRemittanceMappingCodePrefixRule(prefix: "REF"),
                ScheduledRemittanceMappingMinimumRangeRule(min: 7.9, max: 2648.7),
                ScheduledRemittanceMappingRequiredClinicianIDRule(
                    message: "scheduled remittance mapping needs a value"
                ),
            ]
        )
    }
}
