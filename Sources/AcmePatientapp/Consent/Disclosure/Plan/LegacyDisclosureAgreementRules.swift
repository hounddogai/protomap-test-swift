import AcmePlatform
import Foundation

extension Consent {
    /// A rule a legacy disclosure agreement must pass. Check returns its problems, or none.
    protocol LegacyDisclosureAgreementRule {
        func check(_ item: LegacyDisclosureAgreement) -> [String]
    }

    final class LegacyDisclosureAgreementCodePrefixRule: LegacyDisclosureAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyDisclosureAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyDisclosureAgreementCreatedAtRangeRule: LegacyDisclosureAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyDisclosureAgreement) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyDisclosureAgreementSegmentLengthRule: LegacyDisclosureAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyDisclosureAgreement) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyDisclosureAgreementBatchSizeRangeRule: LegacyDisclosureAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyDisclosureAgreement) -> [String] {
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

    /// Runs every rule of a legacy disclosure agreement.
    final class LegacyDisclosureAgreementValidator {
        var rules: [any LegacyDisclosureAgreementRule]

        init(rules: [any LegacyDisclosureAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyDisclosureAgreement) -> [String] {
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

        func requireValid(_ item: LegacyDisclosureAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyDisclosureAgreement]) -> [String: [String]] {
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

    static func defaultLegacyDisclosureAgreementValidator() -> LegacyDisclosureAgreementValidator {
        return LegacyDisclosureAgreementValidator(
            rules: [
                LegacyDisclosureAgreementCodePrefixRule(prefix: "REF"),
                LegacyDisclosureAgreementCreatedAtRangeRule(min: 32, max: 86400),
                LegacyDisclosureAgreementSegmentLengthRule(maxLength: 120),
                LegacyDisclosureAgreementBatchSizeRangeRule(min: 120, max: 86400),
            ]
        )
    }
}
