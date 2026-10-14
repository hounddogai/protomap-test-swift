import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a lenient inventory manifest must pass. Check returns its problems, or none.
    protocol LenientInventoryManifestRule {
        func check(_ item: LenientInventoryManifest) -> [String]
    }

    final class LenientInventoryManifestRequiredCodeRule: LenientInventoryManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientInventoryManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientInventoryManifestOwnerIDLengthRule: LenientInventoryManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientInventoryManifest) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientInventoryManifestRequiredTitleRule: LenientInventoryManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientInventoryManifest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientInventoryManifestRefillsRangeRule: LenientInventoryManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientInventoryManifest) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient inventory manifest.
    final class LenientInventoryManifestValidator {
        var rules: [any LenientInventoryManifestRule]

        init(rules: [any LenientInventoryManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientInventoryManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientInventoryManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientInventoryManifest]) -> [String: [String]] {
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

    static func defaultLenientInventoryManifestValidator() -> LenientInventoryManifestValidator {
        return LenientInventoryManifestValidator(
            rules: [
                LenientInventoryManifestRequiredCodeRule(message: "lenient inventory manifest needs an entry"),
                LenientInventoryManifestOwnerIDLengthRule(maxLength: 120),
                LenientInventoryManifestRequiredTitleRule(message: "lenient inventory manifest needs an entry"),
                LenientInventoryManifestRefillsRangeRule(min: 16, max: 80),
            ]
        )
    }
}
