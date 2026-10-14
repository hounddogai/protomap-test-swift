import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan profile must pass. Check returns its problems, or none.
    protocol AcuityPlanProfileRule {
        func check(_ item: AcuityPlanProfile) -> [String]
    }

    final class AcuityPlanProfileRequiredCodeRule: AcuityPlanProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanProfileCodePrefixRule: AcuityPlanProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AcuityPlanProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AcuityPlanProfileAllowedWardRule: AcuityPlanProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AcuityPlanProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is expired"]
            }
            return []
        }
    }

    final class AcuityPlanProfileRequiredWardRule: AcuityPlanProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanProfile) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanProfileCodeLengthRule: AcuityPlanProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan profile.
    final class AcuityPlanProfileValidator {
        var rules: [any AcuityPlanProfileRule]

        init(rules: [any AcuityPlanProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanProfile) -> [String] {
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

        func requireValid(_ item: AcuityPlanProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanProfile]) -> [String: [String]] {
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

    static func defaultAcuityPlanProfileValidator() -> AcuityPlanProfileValidator {
        return AcuityPlanProfileValidator(
            rules: [
                AcuityPlanProfileRequiredCodeRule(message: "acuity plan profile needs a value"),
                AcuityPlanProfileCodePrefixRule(prefix: "OPS"),
                AcuityPlanProfileAllowedWardRule(allowed: []),
                AcuityPlanProfileRequiredWardRule(message: "acuity plan profile needs a value"),
                AcuityPlanProfileCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
