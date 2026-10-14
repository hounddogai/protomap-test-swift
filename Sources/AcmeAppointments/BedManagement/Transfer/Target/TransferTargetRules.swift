import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer target must pass. Check returns its problems, or none.
    protocol TransferTargetRule {
        func check(_ item: TransferTarget) -> [String]
    }

    final class TransferTargetChannelLengthRule: TransferTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferTarget) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferTargetCodePrefixRule: TransferTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TransferTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TransferTargetActiveGuardRule: TransferTargetRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: TransferTarget) -> [String] {
            if item.active && (item.weight > limit) {
                return ["weight \(item.weight) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class TransferTargetRequiredCodeRule: TransferTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a transfer target.
    final class TransferTargetValidator {
        var rules: [any TransferTargetRule]

        init(rules: [any TransferTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferTarget) -> [String] {
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

        func requireValid(_ item: TransferTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferTarget]) -> [String: [String]] {
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

    static func defaultTransferTargetValidator() -> TransferTargetValidator {
        return TransferTargetValidator(
            rules: [
                TransferTargetChannelLengthRule(maxLength: 64),
                TransferTargetCodePrefixRule(prefix: "REF"),
                TransferTargetActiveGuardRule(limit: 7.9),
                TransferTargetRequiredCodeRule(message: "transfer target needs this field"),
            ]
        )
    }
}
