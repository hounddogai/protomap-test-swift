import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool bundle must pass. Check returns its problems, or none.
    protocol FloatPoolBundleRule {
        func check(_ item: FloatPoolBundle) -> [String]
    }

    final class FloatPoolBundleRequiredLabelRule: FloatPoolBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolBundle) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolBundleRequiredOwnerIDRule: FloatPoolBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolBundle) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolBundleLabelLengthRule: FloatPoolBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolBundle) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolBundleVersionRangeRule: FloatPoolBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolBundle) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FloatPoolBundleAllowedCodeRule: FloatPoolBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FloatPoolBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    /// Runs every rule of a float pool bundle.
    final class FloatPoolBundleValidator {
        var rules: [any FloatPoolBundleRule]

        init(rules: [any FloatPoolBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolBundle) -> [String] {
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

        func requireValid(_ item: FloatPoolBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolBundle]) -> [String: [String]] {
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

    static func defaultFloatPoolBundleValidator() -> FloatPoolBundleValidator {
        return FloatPoolBundleValidator(
            rules: [
                FloatPoolBundleRequiredLabelRule(message: "float pool bundle needs an entry"),
                FloatPoolBundleRequiredOwnerIDRule(message: "float pool bundle needs an entry"),
                FloatPoolBundleLabelLengthRule(maxLength: 1000),
                FloatPoolBundleVersionRangeRule(min: 80, max: 86400),
                FloatPoolBundleAllowedCodeRule(allowed: []),
            ]
        )
    }
}
