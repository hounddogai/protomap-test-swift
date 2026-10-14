import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction manifest must pass. Check returns its problems, or none.
    protocol InteractionManifestRule {
        func check(_ item: InteractionManifest) -> [String]
    }

    final class InteractionManifestTagsLimitRule: InteractionManifestRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: InteractionManifest) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class InteractionManifestFacilityLengthRule: InteractionManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionManifest) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionManifestCodeLengthRule: InteractionManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionManifestNameLengthRule: InteractionManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionManifest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a interaction manifest.
    final class InteractionManifestValidator {
        var rules: [any InteractionManifestRule]

        init(rules: [any InteractionManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InteractionManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionManifest]) -> [String: [String]] {
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

    static func defaultInteractionManifestValidator() -> InteractionManifestValidator {
        return InteractionManifestValidator(
            rules: [
                InteractionManifestTagsLimitRule(maxCount: 255, banned: ["lenient", "pending", "adaptive"]),
                InteractionManifestFacilityLengthRule(maxLength: 80),
                InteractionManifestCodeLengthRule(maxLength: 3600),
                InteractionManifestNameLengthRule(maxLength: 1000),
            ]
        )
    }
}
