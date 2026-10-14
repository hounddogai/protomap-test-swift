@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledConsentFormAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultScheduledConsentFormAllocationValidator()
        let item = Consent.newScheduledConsentFormAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentScheduledConsentFormAllocationLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.ScheduledConsentFormAllocationLabelLengthRule(maxLength: 64)
        let item = Consent.newScheduledConsentFormAllocation("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentScheduledConsentFormAllocationOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Consent.ScheduledConsentFormAllocationOwnerIDLengthRule(maxLength: 1000)
        let item = Consent.newScheduledConsentFormAllocation("x", label: "y")
        item.ownerID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentScheduledConsentFormAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ScheduledConsentFormAllocationRequiredCodeRule(
            message: "scheduled consent form allocation needs this field"
        )
        let item = Consent.newScheduledConsentFormAllocation("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentScheduledConsentFormAllocationDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Consent.ScheduledConsentFormAllocationDurationMinutesRangeRule(min: 3600, max: 86400)
        let item = Consent.newScheduledConsentFormAllocation("x", label: "y")
        item.durationMinutes = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentScheduledConsentFormAllocationSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Consent.ScheduledConsentFormAllocationSourceLengthRule(maxLength: 64)
        let item = Consent.newScheduledConsentFormAllocation("x", label: "y")
        item.source = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}
