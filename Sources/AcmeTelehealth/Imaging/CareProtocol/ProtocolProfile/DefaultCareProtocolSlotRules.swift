import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a default care protocol slot must pass. Check returns its problems, or none.
    protocol DefaultCareProtocolSlotRule {
        func check(_ item: DefaultCareProtocolSlot) -> [String]
    }

    final class DefaultCareProtocolSlotNameLengthRule: DefaultCareProtocolSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCareProtocolSlot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultCareProtocolSlotEndsAtRangeRule: DefaultCareProtocolSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultCareProtocolSlot) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultCareProtocolSlotDiscountRangeRule: DefaultCareProtocolSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultCareProtocolSlot) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a default care protocol slot.
    final class DefaultCareProtocolSlotValidator {
        var rules: [any DefaultCareProtocolSlotRule]

        init(rules: [any DefaultCareProtocolSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultCareProtocolSlot) -> [String] {
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

        func requireValid(_ item: DefaultCareProtocolSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultCareProtocolSlot]) -> [String: [String]] {
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

    static func defaultDefaultCareProtocolSlotValidator() -> DefaultCareProtocolSlotValidator {
        return DefaultCareProtocolSlotValidator(
            rules: [
                DefaultCareProtocolSlotNameLengthRule(maxLength: 120),
                DefaultCareProtocolSlotEndsAtRangeRule(min: 16, max: 16),
                DefaultCareProtocolSlotDiscountRangeRule(min: 5.5, max: 163.8),
            ]
        )
    }
}
