import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a manual discharge plan item must pass. Check returns its problems, or none.
    protocol ManualDischargePlanItemRule {
        func check(_ item: ManualDischargePlanItem) -> [String]
    }

    final class ManualDischargePlanItemRequiredTitleRule: ManualDischargePlanItemRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualDischargePlanItem) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualDischargePlanItemLimitRangeRule: ManualDischargePlanItemRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualDischargePlanItem) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualDischargePlanItemTitleLengthRule: ManualDischargePlanItemRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualDischargePlanItem) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualDischargePlanItemPhoneLengthRule: ManualDischargePlanItemRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualDischargePlanItem) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualDischargePlanItemVersionRangeRule: ManualDischargePlanItemRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualDischargePlanItem) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualDischargePlanItemRequiredClinicianIDRule: ManualDischargePlanItemRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualDischargePlanItem) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual discharge plan item.
    final class ManualDischargePlanItemValidator {
        var rules: [any ManualDischargePlanItemRule]

        init(rules: [any ManualDischargePlanItemRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualDischargePlanItem) -> [String] {
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

        func requireValid(_ item: ManualDischargePlanItem) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualDischargePlanItem]) -> [String: [String]] {
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

    static func defaultManualDischargePlanItemValidator() -> ManualDischargePlanItemValidator {
        return ManualDischargePlanItemValidator(
            rules: [
                ManualDischargePlanItemRequiredTitleRule(message: "manual discharge plan item needs this field"),
                ManualDischargePlanItemLimitRangeRule(min: 32, max: 1000),
                ManualDischargePlanItemTitleLengthRule(maxLength: 80),
                ManualDischargePlanItemPhoneLengthRule(maxLength: 32),
                ManualDischargePlanItemVersionRangeRule(min: 16, max: 3600),
                ManualDischargePlanItemRequiredClinicianIDRule(message: "manual discharge plan item needs an entry"),
            ]
        )
    }
}
