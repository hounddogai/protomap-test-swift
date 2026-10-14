import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a batched slot agreement must pass. Check returns its problems, or none.
    protocol BatchedSlotAgreementRule {
        func check(_ item: BatchedSlotAgreement) -> [String]
    }

    final class BatchedSlotAgreementRequiredCodeRule: BatchedSlotAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedSlotAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedSlotAgreementTitleLengthRule: BatchedSlotAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedSlotAgreement) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedSlotAgreementSegmentLengthRule: BatchedSlotAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedSlotAgreement) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedSlotAgreementRequiredPhoneRule: BatchedSlotAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedSlotAgreement) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedSlotAgreementDosageMgRangeRule: BatchedSlotAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedSlotAgreement) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a batched slot agreement.
    final class BatchedSlotAgreementValidator {
        var rules: [any BatchedSlotAgreementRule]

        init(rules: [any BatchedSlotAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedSlotAgreement) -> [String] {
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

        func requireValid(_ item: BatchedSlotAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedSlotAgreement]) -> [String: [String]] {
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

    static func defaultBatchedSlotAgreementValidator() -> BatchedSlotAgreementValidator {
        return BatchedSlotAgreementValidator(
            rules: [
                BatchedSlotAgreementRequiredCodeRule(message: "batched slot agreement needs this field"),
                BatchedSlotAgreementTitleLengthRule(maxLength: 255),
                BatchedSlotAgreementSegmentLengthRule(maxLength: 16),
                BatchedSlotAgreementRequiredPhoneRule(message: "batched slot agreement needs this field"),
                BatchedSlotAgreementDosageMgRangeRule(min: 8.6, max: 228.2),
            ]
        )
    }
}
