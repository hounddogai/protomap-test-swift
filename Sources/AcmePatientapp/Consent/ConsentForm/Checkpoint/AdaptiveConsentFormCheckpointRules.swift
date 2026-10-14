import AcmePlatform
import Foundation

extension Consent {
    /// A rule a adaptive consent form checkpoint must pass. Check returns its problems, or none.
    protocol AdaptiveConsentFormCheckpointRule {
        func check(_ item: AdaptiveConsentFormCheckpoint) -> [String]
    }

    final class AdaptiveConsentFormCheckpointArchivedGuardRule: AdaptiveConsentFormCheckpointRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: AdaptiveConsentFormCheckpoint) -> [String] {
            if item.archived && (item.version > limit) {
                return ["version \(item.version) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class AdaptiveConsentFormCheckpointCodePrefixRule: AdaptiveConsentFormCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveConsentFormCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveConsentFormCheckpointClinicianIDLengthRule: AdaptiveConsentFormCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveConsentFormCheckpoint) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveConsentFormCheckpointRequiredNameRule: AdaptiveConsentFormCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveConsentFormCheckpoint) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveConsentFormCheckpointVersionRangeRule: AdaptiveConsentFormCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveConsentFormCheckpoint) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveConsentFormCheckpointSequenceRangeRule: AdaptiveConsentFormCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveConsentFormCheckpoint) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a adaptive consent form checkpoint.
    final class AdaptiveConsentFormCheckpointValidator {
        var rules: [any AdaptiveConsentFormCheckpointRule]

        init(rules: [any AdaptiveConsentFormCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveConsentFormCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveConsentFormCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveConsentFormCheckpoint]) -> [String: [String]] {
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

    static func defaultAdaptiveConsentFormCheckpointValidator() -> AdaptiveConsentFormCheckpointValidator {
        return AdaptiveConsentFormCheckpointValidator(
            rules: [
                AdaptiveConsentFormCheckpointArchivedGuardRule(limit: 86400),
                AdaptiveConsentFormCheckpointCodePrefixRule(prefix: "ACM"),
                AdaptiveConsentFormCheckpointClinicianIDLengthRule(maxLength: 1000),
                AdaptiveConsentFormCheckpointRequiredNameRule(
                    message: "adaptive consent form checkpoint needs a value"
                ),
                AdaptiveConsentFormCheckpointVersionRangeRule(min: 16, max: 86400),
                AdaptiveConsentFormCheckpointSequenceRangeRule(min: 120, max: 255),
            ]
        )
    }
}
