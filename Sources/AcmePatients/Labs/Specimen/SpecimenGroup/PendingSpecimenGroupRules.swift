import AcmePlatform
import Foundation

extension Labs {
    /// A rule a pending specimen group must pass. Check returns its problems, or none.
    protocol PendingSpecimenGroupRule {
        func check(_ item: PendingSpecimenGroup) -> [String]
    }

    final class PendingSpecimenGroupRequiredCodeRule: PendingSpecimenGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingSpecimenGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingSpecimenGroupLabelLengthRule: PendingSpecimenGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingSpecimenGroup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingSpecimenGroupBatchSizeRangeRule: PendingSpecimenGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingSpecimenGroup) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingSpecimenGroupRequiredProcedureCodeRule: PendingSpecimenGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingSpecimenGroup) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingSpecimenGroupProcedureCodeLengthRule: PendingSpecimenGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingSpecimenGroup) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingSpecimenGroupCodePrefixRule: PendingSpecimenGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingSpecimenGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending specimen group.
    final class PendingSpecimenGroupValidator {
        var rules: [any PendingSpecimenGroupRule]

        init(rules: [any PendingSpecimenGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingSpecimenGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingSpecimenGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingSpecimenGroup]) -> [String: [String]] {
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

    static func defaultPendingSpecimenGroupValidator() -> PendingSpecimenGroupValidator {
        return PendingSpecimenGroupValidator(
            rules: [
                PendingSpecimenGroupRequiredCodeRule(message: "pending specimen group needs an entry"),
                PendingSpecimenGroupLabelLengthRule(maxLength: 3600),
                PendingSpecimenGroupBatchSizeRangeRule(min: 80, max: 86400),
                PendingSpecimenGroupRequiredProcedureCodeRule(message: "pending specimen group needs an entry"),
                PendingSpecimenGroupProcedureCodeLengthRule(maxLength: 80),
                PendingSpecimenGroupCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
