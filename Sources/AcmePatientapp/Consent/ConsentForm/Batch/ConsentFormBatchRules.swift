import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form batch must pass. Check returns its problems, or none.
    protocol ConsentFormBatchRule {
        func check(_ item: ConsentFormBatch) -> [String]
    }

    final class ConsentFormBatchRequiredCountryRule: ConsentFormBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormBatch) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormBatchRequiredDescriptionRule: ConsentFormBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormBatch) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormBatchRequiredCodeRule: ConsentFormBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormBatchRequiredNameRule: ConsentFormBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormBatch) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a consent form batch.
    final class ConsentFormBatchValidator {
        var rules: [any ConsentFormBatchRule]

        init(rules: [any ConsentFormBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ConsentFormBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormBatch]) -> [String: [String]] {
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

    static func defaultConsentFormBatchValidator() -> ConsentFormBatchValidator {
        return ConsentFormBatchValidator(
            rules: [
                ConsentFormBatchRequiredCountryRule(message: "consent form batch needs a value"),
                ConsentFormBatchRequiredDescriptionRule(message: "consent form batch needs an entry"),
                ConsentFormBatchRequiredCodeRule(message: "consent form batch needs this field"),
                ConsentFormBatchRequiredNameRule(message: "consent form batch needs this field"),
            ]
        )
    }
}
