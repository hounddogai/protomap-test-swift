import AcmePlatform
import Foundation

extension Labs {
    /// A rule a manual result baseline must pass. Check returns its problems, or none.
    protocol ManualResultBaselineRule {
        func check(_ item: ManualResultBaseline) -> [String]
    }

    final class ManualResultBaselineRequiredCodeRule: ManualResultBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualResultBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualResultBaselineLocaleLengthRule: ManualResultBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualResultBaseline) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualResultBaselineAllowedFacilityRule: ManualResultBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualResultBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is duplicated"]
            }
            return []
        }
    }

    final class ManualResultBaselineFacilityLengthRule: ManualResultBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualResultBaseline) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual result baseline.
    final class ManualResultBaselineValidator {
        var rules: [any ManualResultBaselineRule]

        init(rules: [any ManualResultBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualResultBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualResultBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualResultBaseline]) -> [String: [String]] {
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

    static func defaultManualResultBaselineValidator() -> ManualResultBaselineValidator {
        return ManualResultBaselineValidator(
            rules: [
                ManualResultBaselineRequiredCodeRule(message: "manual result baseline needs an entry"),
                ManualResultBaselineLocaleLengthRule(maxLength: 3600),
                ManualResultBaselineAllowedFacilityRule(allowed: ["manual", "weighted", "capped"]),
                ManualResultBaselineFacilityLengthRule(maxLength: 86400),
            ]
        )
    }
}
