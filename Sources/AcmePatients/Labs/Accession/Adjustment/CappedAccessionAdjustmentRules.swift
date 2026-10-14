import AcmePlatform
import Foundation

extension Labs {
    /// A rule a capped accession adjustment must pass. Check returns its problems, or none.
    protocol CappedAccessionAdjustmentRule {
        func check(_ item: CappedAccessionAdjustment) -> [String]
    }

    final class CappedAccessionAdjustmentCodeLengthRule: CappedAccessionAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedAccessionAdjustment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedAccessionAdjustmentProcedureCodeLengthRule: CappedAccessionAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedAccessionAdjustment) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedAccessionAdjustmentAllowedContactEmailRule: CappedAccessionAdjustmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedAccessionAdjustment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is duplicated"]
            }
            return []
        }
    }

    final class CappedAccessionAdjustmentLabelLengthRule: CappedAccessionAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedAccessionAdjustment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedAccessionAdjustmentRequiredProcedureCodeRule: CappedAccessionAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedAccessionAdjustment) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped accession adjustment.
    final class CappedAccessionAdjustmentValidator {
        var rules: [any CappedAccessionAdjustmentRule]

        init(rules: [any CappedAccessionAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedAccessionAdjustment) -> [String] {
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

        func requireValid(_ item: CappedAccessionAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedAccessionAdjustment]) -> [String: [String]] {
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

    static func defaultCappedAccessionAdjustmentValidator() -> CappedAccessionAdjustmentValidator {
        return CappedAccessionAdjustmentValidator(
            rules: [
                CappedAccessionAdjustmentCodeLengthRule(maxLength: 80),
                CappedAccessionAdjustmentProcedureCodeLengthRule(maxLength: 120),
                CappedAccessionAdjustmentAllowedContactEmailRule(allowed: ["manual", "adaptive"]),
                CappedAccessionAdjustmentLabelLengthRule(maxLength: 1000),
                CappedAccessionAdjustmentRequiredProcedureCodeRule(
                    message: "capped accession adjustment needs an entry"
                ),
            ]
        )
    }
}
