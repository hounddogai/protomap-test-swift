import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a capped slot profile must pass. Check returns its problems, or none.
    protocol CappedSlotProfileRule {
        func check(_ item: CappedSlotProfile) -> [String]
    }

    final class CappedSlotProfileCodeLengthRule: CappedSlotProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedSlotProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedSlotProfileRequiredCodeRule: CappedSlotProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedSlotProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedSlotProfileVisibleGuardRule: CappedSlotProfileRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CappedSlotProfile) -> [String] {
            if item.visible && (item.limit > limit) {
                return ["limit \(item.limit) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class CappedSlotProfileTitleLengthRule: CappedSlotProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedSlotProfile) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedSlotProfileFloorValueRangeRule: CappedSlotProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedSlotProfile) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped slot profile.
    final class CappedSlotProfileValidator {
        var rules: [any CappedSlotProfileRule]

        init(rules: [any CappedSlotProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedSlotProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedSlotProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedSlotProfile]) -> [String: [String]] {
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

    static func defaultCappedSlotProfileValidator() -> CappedSlotProfileValidator {
        return CappedSlotProfileValidator(
            rules: [
                CappedSlotProfileCodeLengthRule(maxLength: 120),
                CappedSlotProfileRequiredCodeRule(message: "capped slot profile needs this field"),
                CappedSlotProfileVisibleGuardRule(limit: 32),
                CappedSlotProfileTitleLengthRule(maxLength: 1000),
                CappedSlotProfileFloorValueRangeRule(min: 7.1, max: 81.3),
            ]
        )
    }
}
