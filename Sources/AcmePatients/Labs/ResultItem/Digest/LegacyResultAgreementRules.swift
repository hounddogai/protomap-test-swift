import AcmePlatform
import Foundation

extension Labs {
    /// A rule a legacy result agreement must pass. Check returns its problems, or none.
    protocol LegacyResultAgreementRule {
        func check(_ item: LegacyResultAgreement) -> [String]
    }

    final class LegacyResultAgreementRequiredTitleRule: LegacyResultAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyResultAgreement) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyResultAgreementMarginRangeRule: LegacyResultAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyResultAgreement) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyResultAgreementCodeLengthRule: LegacyResultAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyResultAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyResultAgreementRequiredCodeRule: LegacyResultAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyResultAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyResultAgreementAllowedSegmentRule: LegacyResultAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyResultAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.segment)) {
                return ["segment \(item.segment) is below minimum"]
            }
            return []
        }
    }

    final class LegacyResultAgreementSegmentLengthRule: LegacyResultAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyResultAgreement) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy result agreement.
    final class LegacyResultAgreementValidator {
        var rules: [any LegacyResultAgreementRule]

        init(rules: [any LegacyResultAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyResultAgreement) -> [String] {
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

        func requireValid(_ item: LegacyResultAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyResultAgreement]) -> [String: [String]] {
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

    static func defaultLegacyResultAgreementValidator() -> LegacyResultAgreementValidator {
        return LegacyResultAgreementValidator(
            rules: [
                LegacyResultAgreementRequiredTitleRule(message: "legacy result agreement needs an entry"),
                LegacyResultAgreementMarginRangeRule(min: 1.4, max: 3224.2),
                LegacyResultAgreementCodeLengthRule(maxLength: 255),
                LegacyResultAgreementRequiredCodeRule(message: "legacy result agreement needs an entry"),
                LegacyResultAgreementAllowedSegmentRule(allowed: []),
                LegacyResultAgreementSegmentLengthRule(maxLength: 255),
            ]
        )
    }
}
