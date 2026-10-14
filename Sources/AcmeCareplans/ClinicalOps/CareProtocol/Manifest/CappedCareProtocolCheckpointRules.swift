import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a capped care protocol checkpoint must pass. Check returns its problems, or none.
    protocol CappedCareProtocolCheckpointRule {
        func check(_ item: CappedCareProtocolCheckpoint) -> [String]
    }

    final class CappedCareProtocolCheckpointAllowedPhoneRule: CappedCareProtocolCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedCareProtocolCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.phone)) {
                return ["phone \(item.phone) is duplicated"]
            }
            return []
        }
    }

    final class CappedCareProtocolCheckpointRequiredClinicianIDRule: CappedCareProtocolCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedCareProtocolCheckpoint) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedCareProtocolCheckpointRequiredCodeRule: CappedCareProtocolCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedCareProtocolCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedCareProtocolCheckpointCodePrefixRule: CappedCareProtocolCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedCareProtocolCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedCareProtocolCheckpointAttemptsRangeRule: CappedCareProtocolCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedCareProtocolCheckpoint) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedCareProtocolCheckpointCodeLengthRule: CappedCareProtocolCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedCareProtocolCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped care protocol checkpoint.
    final class CappedCareProtocolCheckpointValidator {
        var rules: [any CappedCareProtocolCheckpointRule]

        init(rules: [any CappedCareProtocolCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedCareProtocolCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedCareProtocolCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedCareProtocolCheckpoint]) -> [String: [String]] {
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

    static func defaultCappedCareProtocolCheckpointValidator() -> CappedCareProtocolCheckpointValidator {
        return CappedCareProtocolCheckpointValidator(
            rules: [
                CappedCareProtocolCheckpointAllowedPhoneRule(allowed: []),
                CappedCareProtocolCheckpointRequiredClinicianIDRule(
                    message: "capped care protocol checkpoint needs this field"
                ),
                CappedCareProtocolCheckpointRequiredCodeRule(
                    message: "capped care protocol checkpoint needs this field"
                ),
                CappedCareProtocolCheckpointCodePrefixRule(prefix: "OPS"),
                CappedCareProtocolCheckpointAttemptsRangeRule(min: 80, max: 255),
                CappedCareProtocolCheckpointCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
