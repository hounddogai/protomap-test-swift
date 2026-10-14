import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol agreement must pass. Check returns its problems, or none.
    protocol CareProtocolAgreementRule {
        func check(_ item: CareProtocolAgreement) -> [String]
    }

    final class CareProtocolAgreementUpdatedAtRangeRule: CareProtocolAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolAgreement) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareProtocolAgreementBedLengthRule: CareProtocolAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolAgreement) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolAgreementCapacityRangeRule: CareProtocolAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolAgreement) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a care protocol agreement.
    final class CareProtocolAgreementValidator {
        var rules: [any CareProtocolAgreementRule]

        init(rules: [any CareProtocolAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolAgreement]) -> [String: [String]] {
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

    static func defaultCareProtocolAgreementValidator() -> CareProtocolAgreementValidator {
        return CareProtocolAgreementValidator(
            rules: [
                CareProtocolAgreementUpdatedAtRangeRule(min: 80, max: 3600),
                CareProtocolAgreementBedLengthRule(maxLength: 64),
                CareProtocolAgreementCapacityRangeRule(min: 80, max: 1000),
            ]
        )
    }
}
