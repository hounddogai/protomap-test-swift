import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a manual modality mapping must pass. Check returns its problems, or none.
    protocol ManualModalityMappingRule {
        func check(_ item: ManualModalityMapping) -> [String]
    }

    final class ManualModalityMappingRequiredCodeRule: ManualModalityMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualModalityMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualModalityMappingTitleLengthRule: ManualModalityMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualModalityMapping) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualModalityMappingCodeLengthRule: ManualModalityMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualModalityMapping) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualModalityMappingAcuityRangeRule: ManualModalityMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualModalityMapping) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualModalityMappingAllowedExternalRefRule: ManualModalityMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualModalityMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a manual modality mapping.
    final class ManualModalityMappingValidator {
        var rules: [any ManualModalityMappingRule]

        init(rules: [any ManualModalityMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualModalityMapping) -> [String] {
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

        func requireValid(_ item: ManualModalityMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualModalityMapping]) -> [String: [String]] {
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

    static func defaultManualModalityMappingValidator() -> ManualModalityMappingValidator {
        return ManualModalityMappingValidator(
            rules: [
                ManualModalityMappingRequiredCodeRule(message: "manual modality mapping needs an entry"),
                ManualModalityMappingTitleLengthRule(maxLength: 1000),
                ManualModalityMappingCodeLengthRule(maxLength: 1000),
                ManualModalityMappingAcuityRangeRule(min: 86400, max: 86400),
                ManualModalityMappingAllowedExternalRefRule(allowed: ["weighted"]),
            ]
        )
    }
}
