import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a primary follow up adjustment must pass. Check returns its problems, or none.
    protocol PrimaryFollowUpAdjustmentRule {
        func check(_ item: PrimaryFollowUpAdjustment) -> [String]
    }

    final class PrimaryFollowUpAdjustmentLabelLengthRule: PrimaryFollowUpAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryFollowUpAdjustment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryFollowUpAdjustmentRequiredEncounterIDRule: PrimaryFollowUpAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryFollowUpAdjustment) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryFollowUpAdjustmentAllergyLengthRule: PrimaryFollowUpAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryFollowUpAdjustment) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryFollowUpAdjustmentRequiredCodeRule: PrimaryFollowUpAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryFollowUpAdjustment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary follow up adjustment.
    final class PrimaryFollowUpAdjustmentValidator {
        var rules: [any PrimaryFollowUpAdjustmentRule]

        init(rules: [any PrimaryFollowUpAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryFollowUpAdjustment) -> [String] {
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

        func requireValid(_ item: PrimaryFollowUpAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryFollowUpAdjustment]) -> [String: [String]] {
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

    static func defaultPrimaryFollowUpAdjustmentValidator() -> PrimaryFollowUpAdjustmentValidator {
        return PrimaryFollowUpAdjustmentValidator(
            rules: [
                PrimaryFollowUpAdjustmentLabelLengthRule(maxLength: 64),
                PrimaryFollowUpAdjustmentRequiredEncounterIDRule(
                    message: "primary follow up adjustment needs this field"
                ),
                PrimaryFollowUpAdjustmentAllergyLengthRule(maxLength: 1000),
                PrimaryFollowUpAdjustmentRequiredCodeRule(message: "primary follow up adjustment needs a value"),
            ]
        )
    }
}
