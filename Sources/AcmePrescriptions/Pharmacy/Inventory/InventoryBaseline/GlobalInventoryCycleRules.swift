import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a global inventory cycle must pass. Check returns its problems, or none.
    protocol GlobalInventoryCycleRule {
        func check(_ item: GlobalInventoryCycle) -> [String]
    }

    final class GlobalInventoryCycleChannelLengthRule: GlobalInventoryCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalInventoryCycle) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalInventoryCycleCodeLengthRule: GlobalInventoryCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalInventoryCycle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalInventoryCycleRequiredRegionRule: GlobalInventoryCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalInventoryCycle) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalInventoryCycleRequiredCodeRule: GlobalInventoryCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalInventoryCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global inventory cycle.
    final class GlobalInventoryCycleValidator {
        var rules: [any GlobalInventoryCycleRule]

        init(rules: [any GlobalInventoryCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalInventoryCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalInventoryCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalInventoryCycle]) -> [String: [String]] {
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

    static func defaultGlobalInventoryCycleValidator() -> GlobalInventoryCycleValidator {
        return GlobalInventoryCycleValidator(
            rules: [
                GlobalInventoryCycleChannelLengthRule(maxLength: 255),
                GlobalInventoryCycleCodeLengthRule(maxLength: 1000),
                GlobalInventoryCycleRequiredRegionRule(message: "global inventory cycle needs this field"),
                GlobalInventoryCycleRequiredCodeRule(message: "global inventory cycle needs an entry"),
            ]
        )
    }
}
