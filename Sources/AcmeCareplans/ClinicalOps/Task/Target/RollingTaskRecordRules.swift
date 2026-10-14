import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rolling task record must pass. Check returns its problems, or none.
    protocol RollingTaskRecordRule {
        func check(_ item: RollingTaskRecord) -> [String]
    }

    final class RollingTaskRecordRequiredCodeRule: RollingTaskRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingTaskRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingTaskRecordCodePrefixRule: RollingTaskRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingTaskRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingTaskRecordRevisionRangeRule: RollingTaskRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingTaskRecord) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingTaskRecordSourceLengthRule: RollingTaskRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingTaskRecord) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingTaskRecordAllowedOwnerIDRule: RollingTaskRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingTaskRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is expired"]
            }
            return []
        }
    }

    final class RollingTaskRecordRequiredNameRule: RollingTaskRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingTaskRecord) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling task record.
    final class RollingTaskRecordValidator {
        var rules: [any RollingTaskRecordRule]

        init(rules: [any RollingTaskRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingTaskRecord) -> [String] {
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

        func requireValid(_ item: RollingTaskRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingTaskRecord]) -> [String: [String]] {
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

    static func defaultRollingTaskRecordValidator() -> RollingTaskRecordValidator {
        return RollingTaskRecordValidator(
            rules: [
                RollingTaskRecordRequiredCodeRule(message: "rolling task record needs this field"),
                RollingTaskRecordCodePrefixRule(prefix: "ACM"),
                RollingTaskRecordRevisionRangeRule(min: 80, max: 86400),
                RollingTaskRecordSourceLengthRule(maxLength: 64),
                RollingTaskRecordAllowedOwnerIDRule(allowed: []),
                RollingTaskRecordRequiredNameRule(message: "rolling task record needs a value"),
            ]
        )
    }
}
