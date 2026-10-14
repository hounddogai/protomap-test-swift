import AcmePlatform
import Foundation

extension Labs {
    /// A rule a rolling courier threshold must pass. Check returns its problems, or none.
    protocol RollingCourierThresholdRule {
        func check(_ item: RollingCourierThreshold) -> [String]
    }

    final class RollingCourierThresholdPayerLengthRule: RollingCourierThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingCourierThreshold) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingCourierThresholdCodePrefixRule: RollingCourierThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingCourierThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingCourierThresholdRequiredRegionRule: RollingCourierThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingCourierThreshold) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingCourierThresholdAllowedCodeRule: RollingCourierThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingCourierThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class RollingCourierThresholdRequiredTitleRule: RollingCourierThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingCourierThreshold) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling courier threshold.
    final class RollingCourierThresholdValidator {
        var rules: [any RollingCourierThresholdRule]

        init(rules: [any RollingCourierThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingCourierThreshold) -> [String] {
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

        func requireValid(_ item: RollingCourierThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingCourierThreshold]) -> [String: [String]] {
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

    static func defaultRollingCourierThresholdValidator() -> RollingCourierThresholdValidator {
        return RollingCourierThresholdValidator(
            rules: [
                RollingCourierThresholdPayerLengthRule(maxLength: 64),
                RollingCourierThresholdCodePrefixRule(prefix: "Q"),
                RollingCourierThresholdRequiredRegionRule(message: "rolling courier threshold needs a value"),
                RollingCourierThresholdAllowedCodeRule(allowed: ["rolling"]),
                RollingCourierThresholdRequiredTitleRule(message: "rolling courier threshold needs an entry"),
            ]
        )
    }
}
