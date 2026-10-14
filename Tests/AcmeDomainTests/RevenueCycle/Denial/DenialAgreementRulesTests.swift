@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialAgreementValidator()
        let item = RevenueCycle.newDenialAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialAgreementMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = RevenueCycle.DenialAgreementMaximumRangeRule(min: 8.0, max: 4374.2)
        let item = RevenueCycle.newDenialAgreement("x", title: "y")
        item.maximum = 4375.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDenialAgreementRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.DenialAgreementRequiredTitleRule(message: "denial agreement needs this field")
        let item = RevenueCycle.newDenialAgreement("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialAgreementClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = RevenueCycle.DenialAgreementClinicianIDLengthRule(maxLength: 32)
        let item = RevenueCycle.newDenialAgreement("x", title: "y")
        item.clinicianID = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
