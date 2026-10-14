import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense audit must pass. Check returns its problems, or none.
    protocol DispenseAuditRule {
        func check(_ item: DispenseAudit) -> [String]
    }

    final class DispenseAuditRequiredTitleRule: DispenseAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseAudit) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseAuditRequiredWardRule: DispenseAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseAudit) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseAuditChannelLengthRule: DispenseAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseAudit) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseAuditCodePrefixRule: DispenseAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DispenseAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DispenseAuditCeilingRangeRule: DispenseAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseAudit) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DispenseAuditTitleLengthRule: DispenseAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseAudit) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense audit.
    final class DispenseAuditValidator {
        var rules: [any DispenseAuditRule]

        init(rules: [any DispenseAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DispenseAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseAudit]) -> [String: [String]] {
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

    static func defaultDispenseAuditValidator() -> DispenseAuditValidator {
        return DispenseAuditValidator(
            rules: [
                DispenseAuditRequiredTitleRule(message: "dispense audit needs an entry"),
                DispenseAuditRequiredWardRule(message: "dispense audit needs a value"),
                DispenseAuditChannelLengthRule(maxLength: 80),
                DispenseAuditCodePrefixRule(prefix: "ACM"),
                DispenseAuditCeilingRangeRule(min: 6.1, max: 3132.8),
                DispenseAuditTitleLengthRule(maxLength: 64),
            ]
        )
    }
}
