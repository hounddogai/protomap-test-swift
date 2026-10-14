import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a legacy care protocol entry must pass. Check returns its problems, or none.
    protocol LegacyCareProtocolEntryRule {
        func check(_ item: LegacyCareProtocolEntry) -> [String]
    }

    final class LegacyCareProtocolEntryRequiredCodeRule: LegacyCareProtocolEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyCareProtocolEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyCareProtocolEntryRequiredLabelRule: LegacyCareProtocolEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyCareProtocolEntry) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyCareProtocolEntryAllowedFacilityRule: LegacyCareProtocolEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyCareProtocolEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is expired"]
            }
            return []
        }
    }

    final class LegacyCareProtocolEntryPhoneLengthRule: LegacyCareProtocolEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyCareProtocolEntry) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy care protocol entry.
    final class LegacyCareProtocolEntryValidator {
        var rules: [any LegacyCareProtocolEntryRule]

        init(rules: [any LegacyCareProtocolEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyCareProtocolEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyCareProtocolEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyCareProtocolEntry]) -> [String: [String]] {
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

    static func defaultLegacyCareProtocolEntryValidator() -> LegacyCareProtocolEntryValidator {
        return LegacyCareProtocolEntryValidator(
            rules: [
                LegacyCareProtocolEntryRequiredCodeRule(message: "legacy care protocol entry needs this field"),
                LegacyCareProtocolEntryRequiredLabelRule(message: "legacy care protocol entry needs a value"),
                LegacyCareProtocolEntryAllowedFacilityRule(allowed: ["scheduled"]),
                LegacyCareProtocolEntryPhoneLengthRule(maxLength: 80),
            ]
        )
    }
}
