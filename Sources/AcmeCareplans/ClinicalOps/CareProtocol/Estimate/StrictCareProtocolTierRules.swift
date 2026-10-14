import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a strict care protocol tier must pass. Check returns its problems, or none.
    protocol StrictCareProtocolTierRule {
        func check(_ item: StrictCareProtocolTier) -> [String]
    }

    final class StrictCareProtocolTierOwnerIDLengthRule: StrictCareProtocolTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictCareProtocolTier) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictCareProtocolTierRequiredOwnerIDRule: StrictCareProtocolTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictCareProtocolTier) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictCareProtocolTierTitleLengthRule: StrictCareProtocolTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictCareProtocolTier) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict care protocol tier.
    final class StrictCareProtocolTierValidator {
        var rules: [any StrictCareProtocolTierRule]

        init(rules: [any StrictCareProtocolTierRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictCareProtocolTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictCareProtocolTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictCareProtocolTier]) -> [String: [String]] {
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

    static func defaultStrictCareProtocolTierValidator() -> StrictCareProtocolTierValidator {
        return StrictCareProtocolTierValidator(
            rules: [
                StrictCareProtocolTierOwnerIDLengthRule(maxLength: 120),
                StrictCareProtocolTierRequiredOwnerIDRule(message: "strict care protocol tier needs an entry"),
                StrictCareProtocolTierTitleLengthRule(maxLength: 255),
            ]
        )
    }
}
