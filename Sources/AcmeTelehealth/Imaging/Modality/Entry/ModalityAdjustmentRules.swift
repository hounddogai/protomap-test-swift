import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality adjustment must pass. Check returns its problems, or none.
    protocol ModalityAdjustmentRule {
        func check(_ item: ModalityAdjustment) -> [String]
    }

    final class ModalityAdjustmentCodeLengthRule: ModalityAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityAdjustment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityAdjustmentBedLengthRule: ModalityAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityAdjustment) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityAdjustmentRequiredLabelRule: ModalityAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityAdjustment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityAdjustmentRequiredCodeRule: ModalityAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityAdjustment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityAdjustmentCeilingRangeRule: ModalityAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityAdjustment) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ModalityAdjustmentRequiredSegmentRule: ModalityAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityAdjustment) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a modality adjustment.
    final class ModalityAdjustmentValidator {
        var rules: [any ModalityAdjustmentRule]

        init(rules: [any ModalityAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ModalityAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityAdjustment]) -> [String: [String]] {
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

    static func defaultModalityAdjustmentValidator() -> ModalityAdjustmentValidator {
        return ModalityAdjustmentValidator(
            rules: [
                ModalityAdjustmentCodeLengthRule(maxLength: 64),
                ModalityAdjustmentBedLengthRule(maxLength: 1000),
                ModalityAdjustmentRequiredLabelRule(message: "modality adjustment needs a value"),
                ModalityAdjustmentRequiredCodeRule(message: "modality adjustment needs a value"),
                ModalityAdjustmentCeilingRangeRule(min: 8.4, max: 4847.7),
                ModalityAdjustmentRequiredSegmentRule(message: "modality adjustment needs a value"),
            ]
        )
    }
}
