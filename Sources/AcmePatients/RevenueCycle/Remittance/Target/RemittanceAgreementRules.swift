import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance agreement must pass. Check returns its problems, or none.
    protocol RemittanceAgreementRule {
        func check(_ item: RemittanceAgreement) -> [String]
    }

    final class RemittanceAgreementRequiredCodeRule: RemittanceAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceAgreementSegmentLengthRule: RemittanceAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceAgreement) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceAgreementRequiredTitleRule: RemittanceAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceAgreement) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceAgreementSequenceRangeRule: RemittanceAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceAgreement) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RemittanceAgreementDiscountRangeRule: RemittanceAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceAgreement) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RemittanceAgreementAllowedCodeRule: RemittanceAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RemittanceAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a remittance agreement.
    final class RemittanceAgreementValidator {
        var rules: [any RemittanceAgreementRule]

        init(rules: [any RemittanceAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RemittanceAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceAgreement]) -> [String: [String]] {
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

    static func defaultRemittanceAgreementValidator() -> RemittanceAgreementValidator {
        return RemittanceAgreementValidator(
            rules: [
                RemittanceAgreementRequiredCodeRule(message: "remittance agreement needs a value"),
                RemittanceAgreementSegmentLengthRule(maxLength: 1000),
                RemittanceAgreementRequiredTitleRule(message: "remittance agreement needs this field"),
                RemittanceAgreementSequenceRangeRule(min: 16, max: 86400),
                RemittanceAgreementDiscountRangeRule(min: 6.8, max: 4148.2),
                RemittanceAgreementAllowedCodeRule(allowed: ["tiered", "fallback"]),
            ]
        )
    }
}
