import AcmePlatform
import Foundation

extension Labs {
    /// A rule a strict accession bundle must pass. Check returns its problems, or none.
    protocol StrictAccessionBundleRule {
        func check(_ item: StrictAccessionBundle) -> [String]
    }

    final class StrictAccessionBundleRequiredPatientRefRule: StrictAccessionBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictAccessionBundle) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictAccessionBundleRequiredCodeRule: StrictAccessionBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictAccessionBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictAccessionBundleStartsAtRangeRule: StrictAccessionBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictAccessionBundle) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictAccessionBundleRequiredBedRule: StrictAccessionBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictAccessionBundle) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictAccessionBundleCodePrefixRule: StrictAccessionBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictAccessionBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict accession bundle.
    final class StrictAccessionBundleValidator {
        var rules: [any StrictAccessionBundleRule]

        init(rules: [any StrictAccessionBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictAccessionBundle) -> [String] {
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

        func requireValid(_ item: StrictAccessionBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictAccessionBundle]) -> [String: [String]] {
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

    static func defaultStrictAccessionBundleValidator() -> StrictAccessionBundleValidator {
        return StrictAccessionBundleValidator(
            rules: [
                StrictAccessionBundleRequiredPatientRefRule(message: "strict accession bundle needs a value"),
                StrictAccessionBundleRequiredCodeRule(message: "strict accession bundle needs a value"),
                StrictAccessionBundleStartsAtRangeRule(min: 16, max: 86400),
                StrictAccessionBundleRequiredBedRule(message: "strict accession bundle needs a value"),
                StrictAccessionBundleCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
