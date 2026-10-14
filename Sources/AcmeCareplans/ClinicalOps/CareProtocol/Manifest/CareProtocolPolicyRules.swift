import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol policy must pass. Check returns its problems, or none.
    protocol CareProtocolPolicyRule {
        func check(_ item: CareProtocolPolicy) -> [String]
    }

    final class CareProtocolPolicyRequiredLabelRule: CareProtocolPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolPolicy) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolPolicyRequiredCodeRule: CareProtocolPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolPolicyWindowDaysRangeRule: CareProtocolPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolPolicy) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareProtocolPolicyCodePrefixRule: CareProtocolPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CareProtocolPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CareProtocolPolicyPatientRefLengthRule: CareProtocolPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolPolicy) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolPolicySequenceRangeRule: CareProtocolPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolPolicy) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol policy.
    final class CareProtocolPolicyValidator {
        var rules: [any CareProtocolPolicyRule]

        init(rules: [any CareProtocolPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolPolicy]) -> [String: [String]] {
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

    static func defaultCareProtocolPolicyValidator() -> CareProtocolPolicyValidator {
        return CareProtocolPolicyValidator(
            rules: [
                CareProtocolPolicyRequiredLabelRule(message: "care protocol policy needs this field"),
                CareProtocolPolicyRequiredCodeRule(message: "care protocol policy needs this field"),
                CareProtocolPolicyWindowDaysRangeRule(min: 80, max: 255),
                CareProtocolPolicyCodePrefixRule(prefix: "REF"),
                CareProtocolPolicyPatientRefLengthRule(maxLength: 80),
                CareProtocolPolicySequenceRangeRule(min: 32, max: 255),
            ]
        )
    }
}
