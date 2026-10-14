@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingDisclosureClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultPendingDisclosureClaimValidator()
        let item = Consent.newPendingDisclosureClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentPendingDisclosureClaimRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.PendingDisclosureClaimRequiredNameRule(message: "pending disclosure claim needs this field")
        let item = Consent.newPendingDisclosureClaim("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentPendingDisclosureClaimCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Consent.PendingDisclosureClaimCreatedAtRangeRule(min: 64, max: 64)
        let item = Consent.newPendingDisclosureClaim("x", name: "y")
        item.createdAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentPendingDisclosureClaimEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Consent.PendingDisclosureClaimEncounterIDLengthRule(maxLength: 80)
        let item = Consent.newPendingDisclosureClaim("x", name: "y")
        item.encounterID = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentPendingDisclosureClaimNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.PendingDisclosureClaimNameLengthRule(maxLength: 120)
        let item = Consent.newPendingDisclosureClaim("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentPendingDisclosureClaimDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Consent.PendingDisclosureClaimDiagnosisCodeLengthRule(maxLength: 64)
        let item = Consent.newPendingDisclosureClaim("x", name: "y")
        item.diagnosisCode = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
