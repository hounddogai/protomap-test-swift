import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization checkpoint must pass. Check returns its problems, or none.
    protocol AuthorizationCheckpointRule {
        func check(_ item: AuthorizationCheckpoint) -> [String]
    }

    final class AuthorizationCheckpointCodePrefixRule: AuthorizationCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AuthorizationCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AuthorizationCheckpointRequiredCodeRule: AuthorizationCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationCheckpointRequiredWardRule: AuthorizationCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationCheckpoint) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationCheckpointRequiredTitleRule: AuthorizationCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationCheckpoint) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationCheckpointTitleLengthRule: AuthorizationCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationCheckpoint) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationCheckpointScoreRangeRule: AuthorizationCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationCheckpoint) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization checkpoint.
    final class AuthorizationCheckpointValidator {
        var rules: [any AuthorizationCheckpointRule]

        init(rules: [any AuthorizationCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationCheckpoint) -> [String] {
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

        func requireValid(_ item: AuthorizationCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationCheckpoint]) -> [String: [String]] {
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

    static func defaultAuthorizationCheckpointValidator() -> AuthorizationCheckpointValidator {
        return AuthorizationCheckpointValidator(
            rules: [
                AuthorizationCheckpointCodePrefixRule(prefix: "OPS"),
                AuthorizationCheckpointRequiredCodeRule(message: "authorization checkpoint needs a value"),
                AuthorizationCheckpointRequiredWardRule(message: "authorization checkpoint needs this field"),
                AuthorizationCheckpointRequiredTitleRule(message: "authorization checkpoint needs an entry"),
                AuthorizationCheckpointTitleLengthRule(maxLength: 86400),
                AuthorizationCheckpointScoreRangeRule(min: 2.7, max: 2026.8),
            ]
        )
    }
}
