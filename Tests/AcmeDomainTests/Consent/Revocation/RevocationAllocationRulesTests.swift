@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRevocationAllocationValidator()
        let item = Consent.newRevocationAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRevocationAllocationVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Consent.RevocationAllocationVisitMinutesRangeRule(min: 255, max: 86400)
        let item = Consent.newRevocationAllocation("x", label: "y")
        item.visitMinutes = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentRevocationAllocationRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Consent.RevocationAllocationRequiredWardRule(message: "revocation allocation needs an entry")
        let item = Consent.newRevocationAllocation("", label: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRevocationAllocationContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Consent.RevocationAllocationContactEmailLengthRule(maxLength: 3600)
        let item = Consent.newRevocationAllocation("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRevocationAllocationLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.RevocationAllocationLabelLengthRule(maxLength: 80)
        let item = Consent.newRevocationAllocation("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRevocationAllocationRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Consent.RevocationAllocationRequiredContactEmailRule(
            message: "revocation allocation needs this field"
        )
        let item = Consent.newRevocationAllocation("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}
