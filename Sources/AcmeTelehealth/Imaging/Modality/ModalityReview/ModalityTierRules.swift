import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality tier must pass. Check returns its problems, or none.
    protocol ModalityTierRule {
        func check(_ item: ModalityTier) -> [String]
    }

    final class ModalityTierNameLengthRule: ModalityTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityTier) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityTierCodeLengthRule: ModalityTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityTierVisitMinutesRangeRule: ModalityTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityTier) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ModalityTierWardLengthRule: ModalityTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityTier) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityTierRequiredNameRule: ModalityTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityTier) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityTierBatchSizeRangeRule: ModalityTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityTier) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a modality tier.
    final class ModalityTierValidator {
        var rules: [any ModalityTierRule]

        init(rules: [any ModalityTierRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ModalityTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityTier]) -> [String: [String]] {
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

    static func defaultModalityTierValidator() -> ModalityTierValidator {
        return ModalityTierValidator(
            rules: [
                ModalityTierNameLengthRule(maxLength: 1000),
                ModalityTierCodeLengthRule(maxLength: 64),
                ModalityTierVisitMinutesRangeRule(min: 1000, max: 1000),
                ModalityTierWardLengthRule(maxLength: 64),
                ModalityTierRequiredNameRule(message: "modality tier needs a value"),
                ModalityTierBatchSizeRangeRule(min: 120, max: 86400),
            ]
        )
    }
}
