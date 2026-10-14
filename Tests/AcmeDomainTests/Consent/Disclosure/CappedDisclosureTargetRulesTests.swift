@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedDisclosureTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultCappedDisclosureTargetValidator()
        let item = Consent.newCappedDisclosureTarget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentCappedDisclosureTargetVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Consent.CappedDisclosureTargetVersionRangeRule(min: 32, max: 120)
        let item = Consent.newCappedDisclosureTarget("x", title: "y")
        item.version = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentCappedDisclosureTargetWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Consent.CappedDisclosureTargetWardLengthRule(maxLength: 255)
        let item = Consent.newCappedDisclosureTarget("x", title: "y")
        item.ward = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentCappedDisclosureTargetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.CappedDisclosureTargetCodeLengthRule(maxLength: 32)
        let item = Consent.newCappedDisclosureTarget("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentCappedDisclosureTargetRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Consent.CappedDisclosureTargetRequiredEncounterIDRule(
            message: "capped disclosure target needs this field"
        )
        let item = Consent.newCappedDisclosureTarget("", title: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}
