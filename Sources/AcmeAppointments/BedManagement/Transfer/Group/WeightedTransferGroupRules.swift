import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a weighted transfer group must pass. Check returns its problems, or none.
    protocol WeightedTransferGroupRule {
        func check(_ item: WeightedTransferGroup) -> [String]
    }

    final class WeightedTransferGroupRequiredDiagnosisCodeRule: WeightedTransferGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedTransferGroup) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedTransferGroupCapacityRangeRule: WeightedTransferGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedTransferGroup) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedTransferGroupRequiredTitleRule: WeightedTransferGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedTransferGroup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedTransferGroupAllowedDiagnosisCodeRule: WeightedTransferGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedTransferGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is expired"]
            }
            return []
        }
    }

    final class WeightedTransferGroupLimitRangeRule: WeightedTransferGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedTransferGroup) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedTransferGroupRequiredCodeRule: WeightedTransferGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedTransferGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted transfer group.
    final class WeightedTransferGroupValidator {
        var rules: [any WeightedTransferGroupRule]

        init(rules: [any WeightedTransferGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedTransferGroup) -> [String] {
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

        func requireValid(_ item: WeightedTransferGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedTransferGroup]) -> [String: [String]] {
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

    static func defaultWeightedTransferGroupValidator() -> WeightedTransferGroupValidator {
        return WeightedTransferGroupValidator(
            rules: [
                WeightedTransferGroupRequiredDiagnosisCodeRule(message: "weighted transfer group needs an entry"),
                WeightedTransferGroupCapacityRangeRule(min: 16, max: 3600),
                WeightedTransferGroupRequiredTitleRule(message: "weighted transfer group needs a value"),
                WeightedTransferGroupAllowedDiagnosisCodeRule(allowed: ["seasonal"]),
                WeightedTransferGroupLimitRangeRule(min: 64, max: 3600),
                WeightedTransferGroupRequiredCodeRule(message: "weighted transfer group needs an entry"),
            ]
        )
    }
}
