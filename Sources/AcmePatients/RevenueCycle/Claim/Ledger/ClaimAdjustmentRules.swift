import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim adjustment must pass. Check returns its problems, or none.
    protocol ClaimAdjustmentRule {
        func check(_ item: ClaimAdjustment) -> [String]
    }

    final class ClaimAdjustmentRequiredPatientRefRule: ClaimAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimAdjustment) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimAdjustmentLabelLengthRule: ClaimAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimAdjustment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimAdjustmentDescriptionLengthRule: ClaimAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimAdjustment) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a claim adjustment.
    final class ClaimAdjustmentValidator {
        var rules: [any ClaimAdjustmentRule]

        init(rules: [any ClaimAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClaimAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimAdjustment]) -> [String: [String]] {
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

    static func defaultClaimAdjustmentValidator() -> ClaimAdjustmentValidator {
        return ClaimAdjustmentValidator(
            rules: [
                ClaimAdjustmentRequiredPatientRefRule(message: "claim adjustment needs an entry"),
                ClaimAdjustmentLabelLengthRule(maxLength: 86400),
                ClaimAdjustmentDescriptionLengthRule(maxLength: 16),
            ]
        )
    }
}
