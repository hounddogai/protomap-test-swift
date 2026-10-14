import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range adjustment must pass. Check returns its problems, or none.
    protocol ReferenceRangeAdjustmentRule {
        func check(_ item: ReferenceRangeAdjustment) -> [String]
    }

    final class ReferenceRangeAdjustmentFloorValueRangeRule: ReferenceRangeAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeAdjustment) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferenceRangeAdjustmentLabelLengthRule: ReferenceRangeAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeAdjustment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeAdjustmentCodeLengthRule: ReferenceRangeAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeAdjustment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeAdjustmentArchivedGuardRule: ReferenceRangeAdjustmentRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ReferenceRangeAdjustment) -> [String] {
            if item.archived && (item.floorValue > limit) {
                return ["floor value \(item.floorValue) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class ReferenceRangeAdjustmentCodePrefixRule: ReferenceRangeAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReferenceRangeAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ReferenceRangeAdjustmentRequiredLabelRule: ReferenceRangeAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeAdjustment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a reference range adjustment.
    final class ReferenceRangeAdjustmentValidator {
        var rules: [any ReferenceRangeAdjustmentRule]

        init(rules: [any ReferenceRangeAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferenceRangeAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeAdjustment]) -> [String: [String]] {
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

    static func defaultReferenceRangeAdjustmentValidator() -> ReferenceRangeAdjustmentValidator {
        return ReferenceRangeAdjustmentValidator(
            rules: [
                ReferenceRangeAdjustmentFloorValueRangeRule(min: 2.1, max: 3914.8),
                ReferenceRangeAdjustmentLabelLengthRule(maxLength: 120),
                ReferenceRangeAdjustmentCodeLengthRule(maxLength: 64),
                ReferenceRangeAdjustmentArchivedGuardRule(limit: 8.4),
                ReferenceRangeAdjustmentCodePrefixRule(prefix: "REF"),
                ReferenceRangeAdjustmentRequiredLabelRule(message: "reference range adjustment needs a value"),
            ]
        )
    }
}
