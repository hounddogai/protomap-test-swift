import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan manifest must pass. Check returns its problems, or none.
    protocol AcuityPlanManifestRule {
        func check(_ item: AcuityPlanManifest) -> [String]
    }

    final class AcuityPlanManifestCapacityRangeRule: AcuityPlanManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanManifest) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AcuityPlanManifestNotesLengthRule: AcuityPlanManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanManifest) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanManifestRequiredNameRule: AcuityPlanManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanManifest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanManifestCurrencyLengthRule: AcuityPlanManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanManifest) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan manifest.
    final class AcuityPlanManifestValidator {
        var rules: [any AcuityPlanManifestRule]

        init(rules: [any AcuityPlanManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AcuityPlanManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanManifest]) -> [String: [String]] {
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

    static func defaultAcuityPlanManifestValidator() -> AcuityPlanManifestValidator {
        return AcuityPlanManifestValidator(
            rules: [
                AcuityPlanManifestCapacityRangeRule(min: 16, max: 64),
                AcuityPlanManifestNotesLengthRule(maxLength: 1000),
                AcuityPlanManifestRequiredNameRule(message: "acuity plan manifest needs a value"),
                AcuityPlanManifestCurrencyLengthRule(maxLength: 255),
            ]
        )
    }
}
