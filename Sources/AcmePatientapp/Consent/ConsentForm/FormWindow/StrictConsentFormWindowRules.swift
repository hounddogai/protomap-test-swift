import AcmePlatform
import Foundation

extension Consent {
    /// A rule a strict consent form window must pass. Check returns its problems, or none.
    protocol StrictConsentFormWindowRule {
        func check(_ item: StrictConsentFormWindow) -> [String]
    }

    final class StrictConsentFormWindowCodePrefixRule: StrictConsentFormWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictConsentFormWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictConsentFormWindowRequiredSegmentRule: StrictConsentFormWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictConsentFormWindow) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictConsentFormWindowRequiredClinicianIDRule: StrictConsentFormWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictConsentFormWindow) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictConsentFormWindowFloorValueRangeRule: StrictConsentFormWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictConsentFormWindow) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict consent form window.
    final class StrictConsentFormWindowValidator {
        var rules: [any StrictConsentFormWindowRule]

        init(rules: [any StrictConsentFormWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictConsentFormWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictConsentFormWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictConsentFormWindow]) -> [String: [String]] {
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

    static func defaultStrictConsentFormWindowValidator() -> StrictConsentFormWindowValidator {
        return StrictConsentFormWindowValidator(
            rules: [
                StrictConsentFormWindowCodePrefixRule(prefix: "ACM"),
                StrictConsentFormWindowRequiredSegmentRule(message: "strict consent form window needs an entry"),
                StrictConsentFormWindowRequiredClinicianIDRule(message: "strict consent form window needs a value"),
                StrictConsentFormWindowFloorValueRangeRule(min: 3.8, max: 4887.9),
            ]
        )
    }
}
