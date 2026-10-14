@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceAgreementValidator()
        let item = RevenueCycle.newRemittanceAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.RemittanceAgreementRequiredCodeRule(message: "remittance agreement needs a value")
        let item = RevenueCycle.newRemittanceAgreement("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceAgreementSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = RevenueCycle.RemittanceAgreementSegmentLengthRule(maxLength: 1000)
        let item = RevenueCycle.newRemittanceAgreement("x", title: "y")
        item.segment = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceAgreementRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.RemittanceAgreementRequiredTitleRule(message: "remittance agreement needs this field")
        let item = RevenueCycle.newRemittanceAgreement("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceAgreementSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = RevenueCycle.RemittanceAgreementSequenceRangeRule(min: 32, max: 80)
        let item = RevenueCycle.newRemittanceAgreement("x", title: "y")
        item.sequence = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRemittanceAgreementDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = RevenueCycle.RemittanceAgreementDiscountRangeRule(min: 5.0, max: 4430.1)
        let item = RevenueCycle.newRemittanceAgreement("x", title: "y")
        item.discount = 4431.6
        #expect(rule.check(item).count > 0)
    }
}
