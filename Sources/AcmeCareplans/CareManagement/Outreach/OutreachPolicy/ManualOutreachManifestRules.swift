import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a manual outreach manifest must pass. Check returns its problems, or none.
    protocol ManualOutreachManifestRule {
        func check(_ item: ManualOutreachManifest) -> [String]
    }

    final class ManualOutreachManifestRequiredOwnerIDRule: ManualOutreachManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualOutreachManifest) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualOutreachManifestCountryLengthRule: ManualOutreachManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualOutreachManifest) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualOutreachManifestOwnerIDLengthRule: ManualOutreachManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualOutreachManifest) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualOutreachManifestUpdatedAtRangeRule: ManualOutreachManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualOutreachManifest) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualOutreachManifestCapacityRangeRule: ManualOutreachManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualOutreachManifest) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualOutreachManifestCodePrefixRule: ManualOutreachManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualOutreachManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual outreach manifest.
    final class ManualOutreachManifestValidator {
        var rules: [any ManualOutreachManifestRule]

        init(rules: [any ManualOutreachManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualOutreachManifest) -> [String] {
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

        func requireValid(_ item: ManualOutreachManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualOutreachManifest]) -> [String: [String]] {
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

    static func defaultManualOutreachManifestValidator() -> ManualOutreachManifestValidator {
        return ManualOutreachManifestValidator(
            rules: [
                ManualOutreachManifestRequiredOwnerIDRule(message: "manual outreach manifest needs an entry"),
                ManualOutreachManifestCountryLengthRule(maxLength: 80),
                ManualOutreachManifestOwnerIDLengthRule(maxLength: 32),
                ManualOutreachManifestUpdatedAtRangeRule(min: 80, max: 255),
                ManualOutreachManifestCapacityRangeRule(min: 120, max: 1000),
                ManualOutreachManifestCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
