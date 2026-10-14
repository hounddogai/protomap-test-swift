import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a pending program target must pass. Check returns its problems, or none.
    protocol PendingProgramTargetRule {
        func check(_ item: PendingProgramTarget) -> [String]
    }

    final class PendingProgramTargetArchivedGuardRule: PendingProgramTargetRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: PendingProgramTarget) -> [String] {
            if item.archived && (item.cost > limit) {
                return ["cost \(item.cost) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class PendingProgramTargetRequiredCodeRule: PendingProgramTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingProgramTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingProgramTargetCodeLengthRule: PendingProgramTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingProgramTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending program target.
    final class PendingProgramTargetValidator {
        var rules: [any PendingProgramTargetRule]

        init(rules: [any PendingProgramTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingProgramTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingProgramTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingProgramTarget]) -> [String: [String]] {
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

    static func defaultPendingProgramTargetValidator() -> PendingProgramTargetValidator {
        return PendingProgramTargetValidator(
            rules: [
                PendingProgramTargetArchivedGuardRule(limit: 6.6),
                PendingProgramTargetRequiredCodeRule(message: "pending program target needs a value"),
                PendingProgramTargetCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
