import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap bundle must pass. Check returns its problems, or none.
    protocol CareGapBundleRule {
        func check(_ item: CareGapBundle) -> [String]
    }

    final class CareGapBundleRequiredCodeRule: CareGapBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapBundleAllowedCodeRule: CareGapBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareGapBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class CareGapBundleCodeLengthRule: CareGapBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapBundleWardLengthRule: CareGapBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapBundle) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care gap bundle.
    final class CareGapBundleValidator {
        var rules: [any CareGapBundleRule]

        init(rules: [any CareGapBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareGapBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapBundle]) -> [String: [String]] {
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

    static func defaultCareGapBundleValidator() -> CareGapBundleValidator {
        return CareGapBundleValidator(
            rules: [
                CareGapBundleRequiredCodeRule(message: "care gap bundle needs a value"),
                CareGapBundleAllowedCodeRule(allowed: ["capped", "weighted"]),
                CareGapBundleCodeLengthRule(maxLength: 120),
                CareGapBundleWardLengthRule(maxLength: 80),
            ]
        )
    }
}
