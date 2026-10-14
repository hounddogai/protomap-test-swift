import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board adjustment must pass. Check returns its problems, or none.
    protocol BedBoardAdjustmentRule {
        func check(_ item: BedBoardAdjustment) -> [String]
    }

    final class BedBoardAdjustmentCountryLengthRule: BedBoardAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardAdjustment) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardAdjustmentRequiredCountryRule: BedBoardAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardAdjustment) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardAdjustmentCodeLengthRule: BedBoardAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardAdjustment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardAdjustmentRequiredClinicianIDRule: BedBoardAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardAdjustment) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardAdjustmentAllowedCodeRule: BedBoardAdjustmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BedBoardAdjustment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class BedBoardAdjustmentClinicianIDLengthRule: BedBoardAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardAdjustment) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a bed board adjustment.
    final class BedBoardAdjustmentValidator {
        var rules: [any BedBoardAdjustmentRule]

        init(rules: [any BedBoardAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BedBoardAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardAdjustment]) -> [String: [String]] {
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

    static func defaultBedBoardAdjustmentValidator() -> BedBoardAdjustmentValidator {
        return BedBoardAdjustmentValidator(
            rules: [
                BedBoardAdjustmentCountryLengthRule(maxLength: 120),
                BedBoardAdjustmentRequiredCountryRule(message: "bed board adjustment needs this field"),
                BedBoardAdjustmentCodeLengthRule(maxLength: 3600),
                BedBoardAdjustmentRequiredClinicianIDRule(message: "bed board adjustment needs a value"),
                BedBoardAdjustmentAllowedCodeRule(allowed: ["capped", "default", "adaptive"]),
                BedBoardAdjustmentClinicianIDLengthRule(maxLength: 64),
            ]
        )
    }
}
