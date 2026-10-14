import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form bundle must pass. Check returns its problems, or none.
    protocol ConsentFormBundleRule {
        func check(_ item: ConsentFormBundle) -> [String]
    }

    final class ConsentFormBundleQuantityRangeRule: ConsentFormBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ConsentFormBundle) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ConsentFormBundleRequiredExternalRefRule: ConsentFormBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormBundle) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormBundleSequenceRangeRule: ConsentFormBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ConsentFormBundle) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ConsentFormBundleAllowedNameRule: ConsentFormBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ConsentFormBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a consent form bundle.
    final class ConsentFormBundleValidator {
        var rules: [any ConsentFormBundleRule]

        init(rules: [any ConsentFormBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ConsentFormBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormBundle]) -> [String: [String]] {
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

    static func defaultConsentFormBundleValidator() -> ConsentFormBundleValidator {
        return ConsentFormBundleValidator(
            rules: [
                ConsentFormBundleQuantityRangeRule(min: 32, max: 64),
                ConsentFormBundleRequiredExternalRefRule(message: "consent form bundle needs a value"),
                ConsentFormBundleSequenceRangeRule(min: 1000, max: 86400),
                ConsentFormBundleAllowedNameRule(allowed: ["manual", "lenient", "scheduled"]),
            ]
        )
    }
}
