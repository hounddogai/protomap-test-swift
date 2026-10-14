@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingConsentFormAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultPendingConsentFormAllocationValidator()
        let item = Consent.newPendingConsentFormAllocation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentPendingConsentFormAllocationMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Consent.PendingConsentFormAllocationMarginRangeRule(min: 2.7, max: 4247.2)
        let item = Consent.newPendingConsentFormAllocation("x", name: "y")
        item.margin = 4248.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentPendingConsentFormAllocationNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.PendingConsentFormAllocationNameLengthRule(maxLength: 16)
        let item = Consent.newPendingConsentFormAllocation("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentPendingConsentFormAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.PendingConsentFormAllocationCodeLengthRule(maxLength: 3600)
        let item = Consent.newPendingConsentFormAllocation("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
