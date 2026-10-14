import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a fallback dispense mapping must pass. Check returns its problems, or none.
    protocol FallbackDispenseMappingRule {
        func check(_ item: FallbackDispenseMapping) -> [String]
    }

    final class FallbackDispenseMappingRequiredRegionRule: FallbackDispenseMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackDispenseMapping) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackDispenseMappingOwnerIDLengthRule: FallbackDispenseMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackDispenseMapping) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackDispenseMappingCodeLengthRule: FallbackDispenseMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackDispenseMapping) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackDispenseMappingLabelLengthRule: FallbackDispenseMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackDispenseMapping) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackDispenseMappingAllowedRegionRule: FallbackDispenseMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackDispenseMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.region)) {
                return ["region \(item.region) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback dispense mapping.
    final class FallbackDispenseMappingValidator {
        var rules: [any FallbackDispenseMappingRule]

        init(rules: [any FallbackDispenseMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackDispenseMapping) -> [String] {
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

        func requireValid(_ item: FallbackDispenseMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackDispenseMapping]) -> [String: [String]] {
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

    static func defaultFallbackDispenseMappingValidator() -> FallbackDispenseMappingValidator {
        return FallbackDispenseMappingValidator(
            rules: [
                FallbackDispenseMappingRequiredRegionRule(message: "fallback dispense mapping needs a value"),
                FallbackDispenseMappingOwnerIDLengthRule(maxLength: 32),
                FallbackDispenseMappingCodeLengthRule(maxLength: 16),
                FallbackDispenseMappingLabelLengthRule(maxLength: 3600),
                FallbackDispenseMappingAllowedRegionRule(allowed: ["legacy", "adaptive", "rolling"]),
            ]
        )
    }
}
