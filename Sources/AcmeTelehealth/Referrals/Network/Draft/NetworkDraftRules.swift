import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network draft must pass. Check returns its problems, or none.
    protocol NetworkDraftRule {
        func check(_ item: NetworkDraft) -> [String]
    }

    final class NetworkDraftNameLengthRule: NetworkDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkDraft) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkDraftSequenceRangeRule: NetworkDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkDraft) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class NetworkDraftRequiredCodeRule: NetworkDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkDraftSummaryLengthRule: NetworkDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkDraft) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkDraftRequiredRegionRule: NetworkDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkDraft) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkDraftRequiredNameRule: NetworkDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkDraft) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a network draft.
    final class NetworkDraftValidator {
        var rules: [any NetworkDraftRule]

        init(rules: [any NetworkDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: NetworkDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkDraft]) -> [String: [String]] {
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

    static func defaultNetworkDraftValidator() -> NetworkDraftValidator {
        return NetworkDraftValidator(
            rules: [
                NetworkDraftNameLengthRule(maxLength: 1000),
                NetworkDraftSequenceRangeRule(min: 16, max: 32),
                NetworkDraftRequiredCodeRule(message: "network draft needs this field"),
                NetworkDraftSummaryLengthRule(maxLength: 32),
                NetworkDraftRequiredRegionRule(message: "network draft needs an entry"),
                NetworkDraftRequiredNameRule(message: "network draft needs a value"),
            ]
        )
    }
}
