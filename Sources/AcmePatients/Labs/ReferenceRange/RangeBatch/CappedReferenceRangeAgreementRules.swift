import AcmePlatform
import Foundation

extension Labs {
    /// A rule a capped reference range agreement must pass. Check returns its problems, or none.
    protocol CappedReferenceRangeAgreementRule {
        func check(_ item: CappedReferenceRangeAgreement) -> [String]
    }

    final class CappedReferenceRangeAgreementNameLengthRule: CappedReferenceRangeAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedReferenceRangeAgreement) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedReferenceRangeAgreementEncounterIDLengthRule: CappedReferenceRangeAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedReferenceRangeAgreement) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedReferenceRangeAgreementRequiredCodeRule: CappedReferenceRangeAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedReferenceRangeAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedReferenceRangeAgreementArchivedGuardRule: CappedReferenceRangeAgreementRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CappedReferenceRangeAgreement) -> [String] {
            if item.archived && (item.startsAt > limit) {
                return ["starts at \(item.startsAt) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class CappedReferenceRangeAgreementCodePrefixRule: CappedReferenceRangeAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedReferenceRangeAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedReferenceRangeAgreementCapacityRangeRule: CappedReferenceRangeAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedReferenceRangeAgreement) -> [String] {
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

    /// Runs every rule of a capped reference range agreement.
    final class CappedReferenceRangeAgreementValidator {
        var rules: [any CappedReferenceRangeAgreementRule]

        init(rules: [any CappedReferenceRangeAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedReferenceRangeAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedReferenceRangeAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedReferenceRangeAgreement]) -> [String: [String]] {
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

    static func defaultCappedReferenceRangeAgreementValidator() -> CappedReferenceRangeAgreementValidator {
        return CappedReferenceRangeAgreementValidator(
            rules: [
                CappedReferenceRangeAgreementNameLengthRule(maxLength: 255),
                CappedReferenceRangeAgreementEncounterIDLengthRule(maxLength: 120),
                CappedReferenceRangeAgreementRequiredCodeRule(
                    message: "capped reference range agreement needs this field"
                ),
                CappedReferenceRangeAgreementArchivedGuardRule(limit: 120),
                CappedReferenceRangeAgreementCodePrefixRule(prefix: "Q"),
                CappedReferenceRangeAgreementCapacityRangeRule(min: 120, max: 255),
            ]
        )
    }
}
