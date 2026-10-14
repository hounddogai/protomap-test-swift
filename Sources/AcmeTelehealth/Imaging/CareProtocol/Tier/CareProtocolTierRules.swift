import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol tier must pass. Check returns its problems, or none.
    protocol CareProtocolTierRule {
        func check(_ item: CareProtocolTier) -> [String]
    }

    final class CareProtocolTierPatientRefLengthRule: CareProtocolTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolTier) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolTierTitleLengthRule: CareProtocolTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolTier) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolTierRequiredPatientRefRule: CareProtocolTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolTier) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol tier.
    final class CareProtocolTierValidator {
        var rules: [any CareProtocolTierRule]

        init(rules: [any CareProtocolTierRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolTier) -> [String] {
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

        func requireValid(_ item: CareProtocolTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolTier]) -> [String: [String]] {
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

    static func defaultCareProtocolTierValidator() -> CareProtocolTierValidator {
        return CareProtocolTierValidator(
            rules: [
                CareProtocolTierPatientRefLengthRule(maxLength: 64),
                CareProtocolTierTitleLengthRule(maxLength: 64),
                CareProtocolTierRequiredPatientRefRule(message: "care protocol tier needs this field"),
            ]
        )
    }
}
