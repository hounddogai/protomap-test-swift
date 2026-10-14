import AcmePlatform
import Foundation

extension Labs {
    /// A rule a weighted accession mapping must pass. Check returns its problems, or none.
    protocol WeightedAccessionMappingRule {
        func check(_ item: WeightedAccessionMapping) -> [String]
    }

    final class WeightedAccessionMappingCountryLengthRule: WeightedAccessionMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedAccessionMapping) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedAccessionMappingRegionLengthRule: WeightedAccessionMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedAccessionMapping) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedAccessionMappingCodeLengthRule: WeightedAccessionMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedAccessionMapping) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedAccessionMappingCodePrefixRule: WeightedAccessionMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedAccessionMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedAccessionMappingRequiredTitleRule: WeightedAccessionMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedAccessionMapping) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted accession mapping.
    final class WeightedAccessionMappingValidator {
        var rules: [any WeightedAccessionMappingRule]

        init(rules: [any WeightedAccessionMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedAccessionMapping) -> [String] {
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

        func requireValid(_ item: WeightedAccessionMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedAccessionMapping]) -> [String: [String]] {
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

    static func defaultWeightedAccessionMappingValidator() -> WeightedAccessionMappingValidator {
        return WeightedAccessionMappingValidator(
            rules: [
                WeightedAccessionMappingCountryLengthRule(maxLength: 16),
                WeightedAccessionMappingRegionLengthRule(maxLength: 1000),
                WeightedAccessionMappingCodeLengthRule(maxLength: 80),
                WeightedAccessionMappingCodePrefixRule(prefix: "ACM"),
                WeightedAccessionMappingRequiredTitleRule(message: "weighted accession mapping needs an entry"),
            ]
        )
    }
}
