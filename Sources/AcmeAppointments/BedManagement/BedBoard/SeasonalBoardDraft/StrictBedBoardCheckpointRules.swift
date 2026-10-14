import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a strict bed board checkpoint must pass. Check returns its problems, or none.
    protocol StrictBedBoardCheckpointRule {
        func check(_ item: StrictBedBoardCheckpoint) -> [String]
    }

    final class StrictBedBoardCheckpointPinnedGuardRule: StrictBedBoardCheckpointRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: StrictBedBoardCheckpoint) -> [String] {
            if item.pinned && (item.cost > limit) {
                return ["cost \(item.cost) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class StrictBedBoardCheckpointCodePrefixRule: StrictBedBoardCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictBedBoardCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictBedBoardCheckpointRequiredCurrencyRule: StrictBedBoardCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictBedBoardCheckpoint) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict bed board checkpoint.
    final class StrictBedBoardCheckpointValidator {
        var rules: [any StrictBedBoardCheckpointRule]

        init(rules: [any StrictBedBoardCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictBedBoardCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictBedBoardCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictBedBoardCheckpoint]) -> [String: [String]] {
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

    static func defaultStrictBedBoardCheckpointValidator() -> StrictBedBoardCheckpointValidator {
        return StrictBedBoardCheckpointValidator(
            rules: [
                StrictBedBoardCheckpointPinnedGuardRule(limit: 6.4),
                StrictBedBoardCheckpointCodePrefixRule(prefix: "Q"),
                StrictBedBoardCheckpointRequiredCurrencyRule(message: "strict bed board checkpoint needs a value"),
            ]
        )
    }
}
