import AcmePlatform
import Foundation

extension Consent {
    /// A rule a manual consent form proposal must pass. Check returns its problems, or none.
    protocol ManualConsentFormProposalRule {
        func check(_ item: ManualConsentFormProposal) -> [String]
    }

    final class ManualConsentFormProposalRequiredExternalRefRule: ManualConsentFormProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualConsentFormProposal) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualConsentFormProposalCodeLengthRule: ManualConsentFormProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualConsentFormProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualConsentFormProposalExternalRefLengthRule: ManualConsentFormProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualConsentFormProposal) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualConsentFormProposalRequiredNameRule: ManualConsentFormProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualConsentFormProposal) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualConsentFormProposalCountryLengthRule: ManualConsentFormProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualConsentFormProposal) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualConsentFormProposalVersionRangeRule: ManualConsentFormProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualConsentFormProposal) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual consent form proposal.
    final class ManualConsentFormProposalValidator {
        var rules: [any ManualConsentFormProposalRule]

        init(rules: [any ManualConsentFormProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualConsentFormProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualConsentFormProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualConsentFormProposal]) -> [String: [String]] {
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

    static func defaultManualConsentFormProposalValidator() -> ManualConsentFormProposalValidator {
        return ManualConsentFormProposalValidator(
            rules: [
                ManualConsentFormProposalRequiredExternalRefRule(
                    message: "manual consent form proposal needs a value"
                ),
                ManualConsentFormProposalCodeLengthRule(maxLength: 1000),
                ManualConsentFormProposalExternalRefLengthRule(maxLength: 3600),
                ManualConsentFormProposalRequiredNameRule(message: "manual consent form proposal needs a value"),
                ManualConsentFormProposalCountryLengthRule(maxLength: 86400),
                ManualConsentFormProposalVersionRangeRule(min: 64, max: 120),
            ]
        )
    }
}
