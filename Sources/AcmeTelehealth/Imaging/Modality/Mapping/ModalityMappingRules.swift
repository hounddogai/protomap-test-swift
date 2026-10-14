import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality mapping must pass. Check returns its problems, or none.
    protocol ModalityMappingRule {
        func check(_ item: ModalityMapping) -> [String]
    }

    final class ModalityMappingAllowedCodeRule: ModalityMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ModalityMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class ModalityMappingEndsAtRangeRule: ModalityMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityMapping) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ModalityMappingAmountRangeRule: ModalityMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityMapping) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ModalityMappingCodeLengthRule: ModalityMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityMapping) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a modality mapping.
    final class ModalityMappingValidator {
        var rules: [any ModalityMappingRule]

        init(rules: [any ModalityMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityMapping) -> [String] {
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

        func requireValid(_ item: ModalityMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityMapping]) -> [String: [String]] {
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

    static func defaultModalityMappingValidator() -> ModalityMappingValidator {
        return ModalityMappingValidator(
            rules: [
                ModalityMappingAllowedCodeRule(allowed: ["rolling", "pending", "tiered"]),
                ModalityMappingEndsAtRangeRule(min: 80, max: 1000),
                ModalityMappingAmountRangeRule(min: 3.8, max: 3469.6),
                ModalityMappingCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
