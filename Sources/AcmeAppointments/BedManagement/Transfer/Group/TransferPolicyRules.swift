import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer policy must pass. Check returns its problems, or none.
    protocol TransferPolicyRule {
        func check(_ item: TransferPolicy) -> [String]
    }

    final class TransferPolicyDiagnosisCodeLengthRule: TransferPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferPolicy) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferPolicyRequiredDiagnosisCodeRule: TransferPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferPolicy) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferPolicyCodePrefixRule: TransferPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TransferPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TransferPolicyNameLengthRule: TransferPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferPolicy) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferPolicyGraceDaysRangeRule: TransferPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferPolicy) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TransferPolicyRequiredClinicianIDRule: TransferPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferPolicy) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a transfer policy.
    final class TransferPolicyValidator {
        var rules: [any TransferPolicyRule]

        init(rules: [any TransferPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TransferPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferPolicy]) -> [String: [String]] {
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

    static func defaultTransferPolicyValidator() -> TransferPolicyValidator {
        return TransferPolicyValidator(
            rules: [
                TransferPolicyDiagnosisCodeLengthRule(maxLength: 80),
                TransferPolicyRequiredDiagnosisCodeRule(message: "transfer policy needs a value"),
                TransferPolicyCodePrefixRule(prefix: "REF"),
                TransferPolicyNameLengthRule(maxLength: 80),
                TransferPolicyGraceDaysRangeRule(min: 80, max: 255),
                TransferPolicyRequiredClinicianIDRule(message: "transfer policy needs a value"),
            ]
        )
    }
}
