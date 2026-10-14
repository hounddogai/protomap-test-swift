import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a global bed board manifest must pass. Check returns its problems, or none.
    protocol GlobalBedBoardManifestRule {
        func check(_ item: GlobalBedBoardManifest) -> [String]
    }

    final class GlobalBedBoardManifestOwnerIDLengthRule: GlobalBedBoardManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalBedBoardManifest) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalBedBoardManifestAllowedLabelRule: GlobalBedBoardManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalBedBoardManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is unknown"]
            }
            return []
        }
    }

    final class GlobalBedBoardManifestCostRangeRule: GlobalBedBoardManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalBedBoardManifest) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalBedBoardManifestLabelLengthRule: GlobalBedBoardManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalBedBoardManifest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalBedBoardManifestRequiredCodeRule: GlobalBedBoardManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalBedBoardManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalBedBoardManifestQuantityRangeRule: GlobalBedBoardManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalBedBoardManifest) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a global bed board manifest.
    final class GlobalBedBoardManifestValidator {
        var rules: [any GlobalBedBoardManifestRule]

        init(rules: [any GlobalBedBoardManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalBedBoardManifest) -> [String] {
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

        func requireValid(_ item: GlobalBedBoardManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalBedBoardManifest]) -> [String: [String]] {
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

    static func defaultGlobalBedBoardManifestValidator() -> GlobalBedBoardManifestValidator {
        return GlobalBedBoardManifestValidator(
            rules: [
                GlobalBedBoardManifestOwnerIDLengthRule(maxLength: 255),
                GlobalBedBoardManifestAllowedLabelRule(allowed: ["tiered"]),
                GlobalBedBoardManifestCostRangeRule(min: 5.7, max: 3675.6),
                GlobalBedBoardManifestLabelLengthRule(maxLength: 32),
                GlobalBedBoardManifestRequiredCodeRule(message: "global bed board manifest needs this field"),
                GlobalBedBoardManifestQuantityRangeRule(min: 120, max: 255),
            ]
        )
    }
}
