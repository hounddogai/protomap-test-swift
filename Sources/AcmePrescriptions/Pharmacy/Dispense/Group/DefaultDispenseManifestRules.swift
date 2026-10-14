import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a default dispense manifest must pass. Check returns its problems, or none.
    protocol DefaultDispenseManifestRule {
        func check(_ item: DefaultDispenseManifest) -> [String]
    }

    final class DefaultDispenseManifestRatioRangeRule: DefaultDispenseManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultDispenseManifest) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultDispenseManifestTitleLengthRule: DefaultDispenseManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultDispenseManifest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultDispenseManifestRequiredOwnerIDRule: DefaultDispenseManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultDispenseManifest) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultDispenseManifestCodeLengthRule: DefaultDispenseManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultDispenseManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultDispenseManifestRequiredTimezoneRule: DefaultDispenseManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultDispenseManifest) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultDispenseManifestTimezoneLengthRule: DefaultDispenseManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultDispenseManifest) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default dispense manifest.
    final class DefaultDispenseManifestValidator {
        var rules: [any DefaultDispenseManifestRule]

        init(rules: [any DefaultDispenseManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultDispenseManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultDispenseManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultDispenseManifest]) -> [String: [String]] {
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

    static func defaultDefaultDispenseManifestValidator() -> DefaultDispenseManifestValidator {
        return DefaultDispenseManifestValidator(
            rules: [
                DefaultDispenseManifestRatioRangeRule(min: 6.8, max: 1144.4),
                DefaultDispenseManifestTitleLengthRule(maxLength: 32),
                DefaultDispenseManifestRequiredOwnerIDRule(message: "default dispense manifest needs a value"),
                DefaultDispenseManifestCodeLengthRule(maxLength: 86400),
                DefaultDispenseManifestRequiredTimezoneRule(message: "default dispense manifest needs a value"),
                DefaultDispenseManifestTimezoneLengthRule(maxLength: 32),
            ]
        )
    }
}
