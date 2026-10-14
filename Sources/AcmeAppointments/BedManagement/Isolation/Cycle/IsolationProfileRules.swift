import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation profile must pass. Check returns its problems, or none.
    protocol IsolationProfileRule {
        func check(_ item: IsolationProfile) -> [String]
    }

    final class IsolationProfileNameLengthRule: IsolationProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationProfile) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationProfileRequiredBedRule: IsolationProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationProfile) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationProfileCodePrefixRule: IsolationProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: IsolationProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class IsolationProfileAllowedNameRule: IsolationProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: IsolationProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is out of range"]
            }
            return []
        }
    }

    final class IsolationProfileDiscountRangeRule: IsolationProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationProfile) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a isolation profile.
    final class IsolationProfileValidator {
        var rules: [any IsolationProfileRule]

        init(rules: [any IsolationProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: IsolationProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationProfile]) -> [String: [String]] {
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

    static func defaultIsolationProfileValidator() -> IsolationProfileValidator {
        return IsolationProfileValidator(
            rules: [
                IsolationProfileNameLengthRule(maxLength: 64),
                IsolationProfileRequiredBedRule(message: "isolation profile needs an entry"),
                IsolationProfileCodePrefixRule(prefix: "OPS"),
                IsolationProfileAllowedNameRule(allowed: []),
                IsolationProfileDiscountRangeRule(min: 0.8, max: 2558.6),
            ]
        )
    }
}
