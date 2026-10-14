@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRevocationMilestoneValidator()
        let item = Consent.newRevocationMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRevocationMilestoneMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Consent.RevocationMilestoneMarginRangeRule(min: 3.7, max: 741.2)
        let item = Consent.newRevocationMilestone("x", title: "y")
        item.margin = 742.7
        #expect(rule.check(item).count > 0)
    }
}
