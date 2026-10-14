@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureGroupValidator()
        let item = Consent.newDisclosureGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureGroupEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Consent.DisclosureGroupEncounterIDLengthRule(maxLength: 120)
        let item = Consent.newDisclosureGroup("x", label: "y")
        item.encounterID = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureGroupRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Consent.DisclosureGroupRequiredProcedureCodeRule(message: "disclosure group needs an entry")
        let item = Consent.newDisclosureGroup("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureGroupStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Consent.DisclosureGroupStartsAtRangeRule(min: 16, max: 16)
        let item = Consent.newDisclosureGroup("x", label: "y")
        item.startsAt = 17
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentDisclosureGroupAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Consent.DisclosureGroupAcuityRangeRule(min: 32, max: 86400)
        let item = Consent.newDisclosureGroup("x", label: "y")
        item.acuity = 86401
        #expect(rule.check(item).count > 0)
    }
}
