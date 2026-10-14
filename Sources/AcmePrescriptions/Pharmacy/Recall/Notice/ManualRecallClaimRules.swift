import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a manual recall claim must pass. Check returns its problems, or none.
    protocol ManualRecallClaimRule {
        func check(_ item: ManualRecallClaim) -> [String]
    }

    final class ManualRecallClaimAllowedTitleRule: ManualRecallClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualRecallClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is inconsistent"]
            }
            return []
        }
    }

    final class ManualRecallClaimThresholdRangeRule: ManualRecallClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualRecallClaim) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualRecallClaimRequiredTitleRule: ManualRecallClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRecallClaim) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualRecallClaimTitleLengthRule: ManualRecallClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRecallClaim) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualRecallClaimRequiredCodeRule: ManualRecallClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRecallClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualRecallClaimProcedureCodeLengthRule: ManualRecallClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRecallClaim) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual recall claim.
    final class ManualRecallClaimValidator {
        var rules: [any ManualRecallClaimRule]

        init(rules: [any ManualRecallClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualRecallClaim) -> [String] {
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

        func requireValid(_ item: ManualRecallClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualRecallClaim]) -> [String: [String]] {
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

    static func defaultManualRecallClaimValidator() -> ManualRecallClaimValidator {
        return ManualRecallClaimValidator(
            rules: [
                ManualRecallClaimAllowedTitleRule(allowed: []),
                ManualRecallClaimThresholdRangeRule(min: 1.0, max: 1280.2),
                ManualRecallClaimRequiredTitleRule(message: "manual recall claim needs a value"),
                ManualRecallClaimTitleLengthRule(maxLength: 64),
                ManualRecallClaimRequiredCodeRule(message: "manual recall claim needs a value"),
                ManualRecallClaimProcedureCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
