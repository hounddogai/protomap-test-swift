import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure draft must pass. Check returns its problems, or none.
    protocol ClosureDraftRule {
        func check(_ item: ClosureDraft) -> [String]
    }

    final class ClosureDraftAllergyLengthRule: ClosureDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureDraft) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureDraftNameLengthRule: ClosureDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureDraft) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureDraftQuantityRangeRule: ClosureDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureDraft) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a closure draft.
    final class ClosureDraftValidator {
        var rules: [any ClosureDraftRule]

        init(rules: [any ClosureDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClosureDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureDraft]) -> [String: [String]] {
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

    static func defaultClosureDraftValidator() -> ClosureDraftValidator {
        return ClosureDraftValidator(
            rules: [
                ClosureDraftAllergyLengthRule(maxLength: 32),
                ClosureDraftNameLengthRule(maxLength: 1000),
                ClosureDraftQuantityRangeRule(min: 64, max: 3600),
            ]
        )
    }
}
