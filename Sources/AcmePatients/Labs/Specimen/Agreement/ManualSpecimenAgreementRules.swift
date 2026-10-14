import AcmePlatform
import Foundation

extension Labs {
    /// A rule a manual specimen agreement must pass. Check returns its problems, or none.
    protocol ManualSpecimenAgreementRule {
        func check(_ item: ManualSpecimenAgreement) -> [String]
    }

    final class ManualSpecimenAgreementTitleLengthRule: ManualSpecimenAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualSpecimenAgreement) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualSpecimenAgreementAllowedContactEmailRule: ManualSpecimenAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualSpecimenAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is stale"]
            }
            return []
        }
    }

    final class ManualSpecimenAgreementCreatedAtRangeRule: ManualSpecimenAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualSpecimenAgreement) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualSpecimenAgreementOwnerIDLengthRule: ManualSpecimenAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualSpecimenAgreement) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual specimen agreement.
    final class ManualSpecimenAgreementValidator {
        var rules: [any ManualSpecimenAgreementRule]

        init(rules: [any ManualSpecimenAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualSpecimenAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualSpecimenAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualSpecimenAgreement]) -> [String: [String]] {
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

    static func defaultManualSpecimenAgreementValidator() -> ManualSpecimenAgreementValidator {
        return ManualSpecimenAgreementValidator(
            rules: [
                ManualSpecimenAgreementTitleLengthRule(maxLength: 3600),
                ManualSpecimenAgreementAllowedContactEmailRule(allowed: []),
                ManualSpecimenAgreementCreatedAtRangeRule(min: 32, max: 3600),
                ManualSpecimenAgreementOwnerIDLengthRule(maxLength: 64),
            ]
        )
    }
}
