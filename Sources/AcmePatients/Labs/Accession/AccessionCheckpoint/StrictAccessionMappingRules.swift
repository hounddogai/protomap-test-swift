import AcmePlatform
import Foundation

extension Labs {
    /// A rule a strict accession mapping must pass. Check returns its problems, or none.
    protocol StrictAccessionMappingRule {
        func check(_ item: StrictAccessionMapping) -> [String]
    }

    final class StrictAccessionMappingLabelLengthRule: StrictAccessionMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictAccessionMapping) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictAccessionMappingCodePrefixRule: StrictAccessionMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictAccessionMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictAccessionMappingVersionRangeRule: StrictAccessionMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictAccessionMapping) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictAccessionMappingFacilityLengthRule: StrictAccessionMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictAccessionMapping) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictAccessionMappingRequiredLabelRule: StrictAccessionMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictAccessionMapping) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict accession mapping.
    final class StrictAccessionMappingValidator {
        var rules: [any StrictAccessionMappingRule]

        init(rules: [any StrictAccessionMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictAccessionMapping) -> [String] {
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

        func requireValid(_ item: StrictAccessionMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictAccessionMapping]) -> [String: [String]] {
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

    static func defaultStrictAccessionMappingValidator() -> StrictAccessionMappingValidator {
        return StrictAccessionMappingValidator(
            rules: [
                StrictAccessionMappingLabelLengthRule(maxLength: 255),
                StrictAccessionMappingCodePrefixRule(prefix: "ACM"),
                StrictAccessionMappingVersionRangeRule(min: 80, max: 3600),
                StrictAccessionMappingFacilityLengthRule(maxLength: 1000),
                StrictAccessionMappingRequiredLabelRule(message: "strict accession mapping needs an entry"),
            ]
        )
    }
}
