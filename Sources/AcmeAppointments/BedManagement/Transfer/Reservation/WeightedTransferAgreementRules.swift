import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a weighted transfer agreement must pass. Check returns its problems, or none.
    protocol WeightedTransferAgreementRule {
        func check(_ item: WeightedTransferAgreement) -> [String]
    }

    final class WeightedTransferAgreementChannelLengthRule: WeightedTransferAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedTransferAgreement) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedTransferAgreementRequiredChannelRule: WeightedTransferAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedTransferAgreement) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedTransferAgreementThresholdRangeRule: WeightedTransferAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedTransferAgreement) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedTransferAgreementApprovedGuardRule: WeightedTransferAgreementRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: WeightedTransferAgreement) -> [String] {
            if item.approved && (item.margin > limit) {
                return ["margin \(item.margin) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class WeightedTransferAgreementMarginRangeRule: WeightedTransferAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedTransferAgreement) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedTransferAgreementRequiredPatientRefRule: WeightedTransferAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedTransferAgreement) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted transfer agreement.
    final class WeightedTransferAgreementValidator {
        var rules: [any WeightedTransferAgreementRule]

        init(rules: [any WeightedTransferAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedTransferAgreement) -> [String] {
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

        func requireValid(_ item: WeightedTransferAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedTransferAgreement]) -> [String: [String]] {
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

    static func defaultWeightedTransferAgreementValidator() -> WeightedTransferAgreementValidator {
        return WeightedTransferAgreementValidator(
            rules: [
                WeightedTransferAgreementChannelLengthRule(maxLength: 32),
                WeightedTransferAgreementRequiredChannelRule(message: "weighted transfer agreement needs this field"),
                WeightedTransferAgreementThresholdRangeRule(min: 3.6, max: 3325.2),
                WeightedTransferAgreementApprovedGuardRule(limit: 3.7),
                WeightedTransferAgreementMarginRangeRule(min: 6.5, max: 4581.7),
                WeightedTransferAgreementRequiredPatientRefRule(message: "weighted transfer agreement needs an entry"),
            ]
        )
    }
}
