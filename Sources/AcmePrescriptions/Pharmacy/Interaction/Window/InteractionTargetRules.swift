import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction target must pass. Check returns its problems, or none.
    protocol InteractionTargetRule {
        func check(_ item: InteractionTarget) -> [String]
    }

    final class InteractionTargetRequiredPayerRule: InteractionTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionTarget) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionTargetBedLengthRule: InteractionTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionTarget) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionTargetCodePrefixRule: InteractionTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: InteractionTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class InteractionTargetArchivedGuardRule: InteractionTargetRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: InteractionTarget) -> [String] {
            if item.archived && (item.floorValue > limit) {
                return ["floor value \(item.floorValue) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class InteractionTargetCodeLengthRule: InteractionTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a interaction target.
    final class InteractionTargetValidator {
        var rules: [any InteractionTargetRule]

        init(rules: [any InteractionTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InteractionTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionTarget]) -> [String: [String]] {
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

    static func defaultInteractionTargetValidator() -> InteractionTargetValidator {
        return InteractionTargetValidator(
            rules: [
                InteractionTargetRequiredPayerRule(message: "interaction target needs a value"),
                InteractionTargetBedLengthRule(maxLength: 16),
                InteractionTargetCodePrefixRule(prefix: "Q"),
                InteractionTargetArchivedGuardRule(limit: 8.5),
                InteractionTargetCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
