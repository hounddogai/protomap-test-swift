import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a rolling shift manifest must pass. Check returns its problems, or none.
    protocol RollingShiftManifestRule {
        func check(_ item: RollingShiftManifest) -> [String]
    }

    final class RollingShiftManifestRegionLengthRule: RollingShiftManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingShiftManifest) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingShiftManifestRevisionRangeRule: RollingShiftManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingShiftManifest) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingShiftManifestNameLengthRule: RollingShiftManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingShiftManifest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingShiftManifestOwnerIDLengthRule: RollingShiftManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingShiftManifest) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingShiftManifestRequiredNameRule: RollingShiftManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingShiftManifest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling shift manifest.
    final class RollingShiftManifestValidator {
        var rules: [any RollingShiftManifestRule]

        init(rules: [any RollingShiftManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingShiftManifest) -> [String] {
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

        func requireValid(_ item: RollingShiftManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingShiftManifest]) -> [String: [String]] {
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

    static func defaultRollingShiftManifestValidator() -> RollingShiftManifestValidator {
        return RollingShiftManifestValidator(
            rules: [
                RollingShiftManifestRegionLengthRule(maxLength: 1000),
                RollingShiftManifestRevisionRangeRule(min: 32, max: 255),
                RollingShiftManifestNameLengthRule(maxLength: 3600),
                RollingShiftManifestOwnerIDLengthRule(maxLength: 32),
                RollingShiftManifestRequiredNameRule(message: "rolling shift manifest needs an entry"),
            ]
        )
    }
}
