import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession manifest must pass. Check returns its problems, or none.
    protocol AccessionManifestRule {
        func check(_ item: AccessionManifest) -> [String]
    }

    final class AccessionManifestAmountRangeRule: AccessionManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionManifest) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AccessionManifestRequiredLabelRule: AccessionManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionManifest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionManifestTagsLimitRule: AccessionManifestRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: AccessionManifest) -> [String] {
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

    /// Runs every rule of a accession manifest.
    final class AccessionManifestValidator {
        var rules: [any AccessionManifestRule]

        init(rules: [any AccessionManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionManifest) -> [String] {
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

        func requireValid(_ item: AccessionManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionManifest]) -> [String: [String]] {
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

    static func defaultAccessionManifestValidator() -> AccessionManifestValidator {
        return AccessionManifestValidator(
            rules: [
                AccessionManifestAmountRangeRule(min: 4.7, max: 4755.2),
                AccessionManifestRequiredLabelRule(message: "accession manifest needs an entry"),
                AccessionManifestTagsLimitRule(maxCount: 255, banned: ["primary", "weighted", "tiered"]),
            ]
        )
    }
}
