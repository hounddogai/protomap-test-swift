import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a rolling program batch must pass. Check returns its problems, or none.
    protocol RollingProgramBatchRule {
        func check(_ item: RollingProgramBatch) -> [String]
    }

    final class RollingProgramBatchRequiredProcedureCodeRule: RollingProgramBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingProgramBatch) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingProgramBatchRequiredCodeRule: RollingProgramBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingProgramBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingProgramBatchCodeLengthRule: RollingProgramBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingProgramBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingProgramBatchRequiredNameRule: RollingProgramBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingProgramBatch) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingProgramBatchNameLengthRule: RollingProgramBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingProgramBatch) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingProgramBatchTitleLengthRule: RollingProgramBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingProgramBatch) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling program batch.
    final class RollingProgramBatchValidator {
        var rules: [any RollingProgramBatchRule]

        init(rules: [any RollingProgramBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingProgramBatch) -> [String] {
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

        func requireValid(_ item: RollingProgramBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingProgramBatch]) -> [String: [String]] {
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

    static func defaultRollingProgramBatchValidator() -> RollingProgramBatchValidator {
        return RollingProgramBatchValidator(
            rules: [
                RollingProgramBatchRequiredProcedureCodeRule(message: "rolling program batch needs a value"),
                RollingProgramBatchRequiredCodeRule(message: "rolling program batch needs an entry"),
                RollingProgramBatchCodeLengthRule(maxLength: 80),
                RollingProgramBatchRequiredNameRule(message: "rolling program batch needs this field"),
                RollingProgramBatchNameLengthRule(maxLength: 3600),
                RollingProgramBatchTitleLengthRule(maxLength: 64),
            ]
        )
    }
}
