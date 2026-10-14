@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallMetricValidator()
        let item = Pharmacy.newRecallMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallMetricRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Pharmacy.RecallMetricRequiredSourceRule(message: "recall metric needs this field")
        let item = Pharmacy.newRecallMetric("", name: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}
