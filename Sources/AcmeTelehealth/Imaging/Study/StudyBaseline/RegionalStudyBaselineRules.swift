import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a regional study baseline must pass. Check returns its problems, or none.
    protocol RegionalStudyBaselineRule {
        func check(_ item: RegionalStudyBaseline) -> [String]
    }

    final class RegionalStudyBaselineAllowedEncounterIDRule: RegionalStudyBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalStudyBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.encounterID)) {
                return ["encounter id \(item.encounterID) is out of range"]
            }
            return []
        }
    }

    final class RegionalStudyBaselineNameLengthRule: RegionalStudyBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalStudyBaseline) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalStudyBaselineRequiredFacilityRule: RegionalStudyBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalStudyBaseline) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalStudyBaselineChecksumLengthRule: RegionalStudyBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalStudyBaseline) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalStudyBaselineRequiredCodeRule: RegionalStudyBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalStudyBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional study baseline.
    final class RegionalStudyBaselineValidator {
        var rules: [any RegionalStudyBaselineRule]

        init(rules: [any RegionalStudyBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalStudyBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalStudyBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalStudyBaseline]) -> [String: [String]] {
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

    static func defaultRegionalStudyBaselineValidator() -> RegionalStudyBaselineValidator {
        return RegionalStudyBaselineValidator(
            rules: [
                RegionalStudyBaselineAllowedEncounterIDRule(allowed: ["manual"]),
                RegionalStudyBaselineNameLengthRule(maxLength: 86400),
                RegionalStudyBaselineRequiredFacilityRule(message: "regional study baseline needs this field"),
                RegionalStudyBaselineChecksumLengthRule(maxLength: 64),
                RegionalStudyBaselineRequiredCodeRule(message: "regional study baseline needs a value"),
            ]
        )
    }
}
