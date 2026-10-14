import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a rolling authorization snapshot must pass. Check returns its problems, or none.
    protocol RollingAuthorizationSnapshotRule {
        func check(_ item: RollingAuthorizationSnapshot) -> [String]
    }

    final class RollingAuthorizationSnapshotCodePrefixRule: RollingAuthorizationSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingAuthorizationSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingAuthorizationSnapshotRequiredNameRule: RollingAuthorizationSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAuthorizationSnapshot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingAuthorizationSnapshotAllowedCodeRule: RollingAuthorizationSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingAuthorizationSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class RollingAuthorizationSnapshotPatientRefLengthRule: RollingAuthorizationSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingAuthorizationSnapshot) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling authorization snapshot.
    final class RollingAuthorizationSnapshotValidator {
        var rules: [any RollingAuthorizationSnapshotRule]

        init(rules: [any RollingAuthorizationSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingAuthorizationSnapshot) -> [String] {
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

        func requireValid(_ item: RollingAuthorizationSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingAuthorizationSnapshot]) -> [String: [String]] {
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

    static func defaultRollingAuthorizationSnapshotValidator() -> RollingAuthorizationSnapshotValidator {
        return RollingAuthorizationSnapshotValidator(
            rules: [
                RollingAuthorizationSnapshotCodePrefixRule(prefix: "OPS"),
                RollingAuthorizationSnapshotRequiredNameRule(message: "rolling authorization snapshot needs an entry"),
                RollingAuthorizationSnapshotAllowedCodeRule(allowed: ["regional", "manual", "global"]),
                RollingAuthorizationSnapshotPatientRefLengthRule(maxLength: 80),
            ]
        )
    }
}
