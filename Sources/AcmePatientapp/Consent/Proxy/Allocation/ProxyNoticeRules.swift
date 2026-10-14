import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy notice must pass. Check returns its problems, or none.
    protocol ProxyNoticeRule {
        func check(_ item: ProxyNotice) -> [String]
    }

    final class ProxyNoticeLimitRangeRule: ProxyNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyNotice) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ProxyNoticeRegionLengthRule: ProxyNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyNotice) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyNoticeRequiredFacilityRule: ProxyNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyNotice) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a proxy notice.
    final class ProxyNoticeValidator {
        var rules: [any ProxyNoticeRule]

        init(rules: [any ProxyNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProxyNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyNotice]) -> [String: [String]] {
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

    static func defaultProxyNoticeValidator() -> ProxyNoticeValidator {
        return ProxyNoticeValidator(
            rules: [
                ProxyNoticeLimitRangeRule(min: 32, max: 255),
                ProxyNoticeRegionLengthRule(maxLength: 86400),
                ProxyNoticeRequiredFacilityRule(message: "proxy notice needs this field"),
            ]
        )
    }
}
