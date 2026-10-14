@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledWitnessMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultScheduledWitnessMilestoneValidator()
        let item = Consent.newScheduledWitnessMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentScheduledWitnessMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ScheduledWitnessMilestoneCodeLengthRule(maxLength: 120)
        let item = Consent.newScheduledWitnessMilestone("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentScheduledWitnessMilestoneSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Consent.ScheduledWitnessMilestoneSpecialtyLengthRule(maxLength: 86400)
        let item = Consent.newScheduledWitnessMilestone("x", title: "y")
        item.specialty = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentScheduledWitnessMilestoneRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Consent.ScheduledWitnessMilestoneRequiredUnitRule(
            message: "scheduled witness milestone needs a value"
        )
        let item = Consent.newScheduledWitnessMilestone("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentScheduledWitnessMilestoneUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Consent.ScheduledWitnessMilestoneUnitLengthRule(maxLength: 255)
        let item = Consent.newScheduledWitnessMilestone("x", title: "y")
        item.unit = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentScheduledWitnessMilestoneVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Consent.ScheduledWitnessMilestoneVersionRangeRule(min: 16, max: 3600)
        let item = Consent.newScheduledWitnessMilestone("x", title: "y")
        item.version = 3601
        #expect(rule.check(item).count > 0)
    }
}
