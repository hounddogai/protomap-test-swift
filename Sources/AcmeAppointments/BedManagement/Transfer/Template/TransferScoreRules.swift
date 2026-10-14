import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer score must pass. Check returns its problems, or none.
    protocol TransferScoreRule {
        func check(_ item: TransferScore) -> [String]
    }

    final class TransferScoreRequiredCodeRule: TransferScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferScoreRequiredLabelRule: TransferScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferScore) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferScorePinnedGuardRule: TransferScoreRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: TransferScore) -> [String] {
            if item.pinned && (item.dosageMg > limit) {
                return ["dosage mg \(item.dosageMg) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    /// Runs every rule of a transfer score.
    final class TransferScoreValidator {
        var rules: [any TransferScoreRule]

        init(rules: [any TransferScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TransferScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferScore]) -> [String: [String]] {
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

    static func defaultTransferScoreValidator() -> TransferScoreValidator {
        return TransferScoreValidator(
            rules: [
                TransferScoreRequiredCodeRule(message: "transfer score needs this field"),
                TransferScoreRequiredLabelRule(message: "transfer score needs this field"),
                TransferScorePinnedGuardRule(limit: 9.8),
            ]
        )
    }
}
