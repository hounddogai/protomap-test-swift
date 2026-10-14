import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a global read mapping must pass. Check returns its problems, or none.
    protocol GlobalReadMappingRule {
        func check(_ item: GlobalReadMapping) -> [String]
    }

    final class GlobalReadMappingLabelLengthRule: GlobalReadMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalReadMapping) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalReadMappingRequiredLabelRule: GlobalReadMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalReadMapping) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalReadMappingRequiredRegionRule: GlobalReadMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalReadMapping) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalReadMappingClinicianIDLengthRule: GlobalReadMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalReadMapping) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global read mapping.
    final class GlobalReadMappingValidator {
        var rules: [any GlobalReadMappingRule]

        init(rules: [any GlobalReadMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalReadMapping) -> [String] {
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

        func requireValid(_ item: GlobalReadMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalReadMapping]) -> [String: [String]] {
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

    static func defaultGlobalReadMappingValidator() -> GlobalReadMappingValidator {
        return GlobalReadMappingValidator(
            rules: [
                GlobalReadMappingLabelLengthRule(maxLength: 1000),
                GlobalReadMappingRequiredLabelRule(message: "global read mapping needs this field"),
                GlobalReadMappingRequiredRegionRule(message: "global read mapping needs an entry"),
                GlobalReadMappingClinicianIDLengthRule(maxLength: 120),
            ]
        )
    }
}
