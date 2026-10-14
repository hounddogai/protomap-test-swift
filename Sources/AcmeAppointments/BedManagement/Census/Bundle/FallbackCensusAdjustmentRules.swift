import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a fallback census adjustment must pass. Check returns its problems, or none.
    protocol FallbackCensusAdjustmentRule {
        func check(_ item: FallbackCensusAdjustment) -> [String]
    }

    final class FallbackCensusAdjustmentChecksumLengthRule: FallbackCensusAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCensusAdjustment) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCensusAdjustmentRequiredCodeRule: FallbackCensusAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCensusAdjustment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCensusAdjustmentAmountRangeRule: FallbackCensusAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackCensusAdjustment) -> [String] {
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

    final class FallbackCensusAdjustmentNameLengthRule: FallbackCensusAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCensusAdjustment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback census adjustment.
    final class FallbackCensusAdjustmentValidator {
        var rules: [any FallbackCensusAdjustmentRule]

        init(rules: [any FallbackCensusAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackCensusAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackCensusAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackCensusAdjustment]) -> [String: [String]] {
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

    static func defaultFallbackCensusAdjustmentValidator() -> FallbackCensusAdjustmentValidator {
        return FallbackCensusAdjustmentValidator(
            rules: [
                FallbackCensusAdjustmentChecksumLengthRule(maxLength: 120),
                FallbackCensusAdjustmentRequiredCodeRule(message: "fallback census adjustment needs this field"),
                FallbackCensusAdjustmentAmountRangeRule(min: 5.2, max: 4609.7),
                FallbackCensusAdjustmentNameLengthRule(maxLength: 32),
            ]
        )
    }
}
