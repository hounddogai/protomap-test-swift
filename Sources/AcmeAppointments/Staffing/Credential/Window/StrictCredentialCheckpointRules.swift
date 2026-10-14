import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a strict credential checkpoint must pass. Check returns its problems, or none.
    protocol StrictCredentialCheckpointRule {
        func check(_ item: StrictCredentialCheckpoint) -> [String]
    }

    final class StrictCredentialCheckpointCodeLengthRule: StrictCredentialCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictCredentialCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictCredentialCheckpointQuantityRangeRule: StrictCredentialCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictCredentialCheckpoint) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictCredentialCheckpointAllowedWardRule: StrictCredentialCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictCredentialCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is inconsistent"]
            }
            return []
        }
    }

    final class StrictCredentialCheckpointApprovedGuardRule: StrictCredentialCheckpointRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: StrictCredentialCheckpoint) -> [String] {
            if item.approved && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class StrictCredentialCheckpointRequiredTimezoneRule: StrictCredentialCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictCredentialCheckpoint) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictCredentialCheckpointCodePrefixRule: StrictCredentialCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictCredentialCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict credential checkpoint.
    final class StrictCredentialCheckpointValidator {
        var rules: [any StrictCredentialCheckpointRule]

        init(rules: [any StrictCredentialCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictCredentialCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictCredentialCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictCredentialCheckpoint]) -> [String: [String]] {
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

    static func defaultStrictCredentialCheckpointValidator() -> StrictCredentialCheckpointValidator {
        return StrictCredentialCheckpointValidator(
            rules: [
                StrictCredentialCheckpointCodeLengthRule(maxLength: 255),
                StrictCredentialCheckpointQuantityRangeRule(min: 16, max: 86400),
                StrictCredentialCheckpointAllowedWardRule(allowed: ["capped", "rolling", "pending"]),
                StrictCredentialCheckpointApprovedGuardRule(limit: 3600),
                StrictCredentialCheckpointRequiredTimezoneRule(message: "strict credential checkpoint needs an entry"),
                StrictCredentialCheckpointCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
