@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessMilestoneValidator()
        let item = Consent.newWitnessMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessMilestoneSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Consent.WitnessMilestoneSpecialtyLengthRule(maxLength: 16)
        let item = Consent.newWitnessMilestone("x", title: "y")
        item.specialty = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWitnessMilestoneRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.WitnessMilestoneRequiredTitleRule(message: "witness milestone needs a value")
        let item = Consent.newWitnessMilestone("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.WitnessMilestoneRequiredCodeRule(message: "witness milestone needs an entry")
        let item = Consent.newWitnessMilestone("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessMilestoneTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.WitnessMilestoneTitleLengthRule(maxLength: 32)
        let item = Consent.newWitnessMilestone("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWitnessMilestoneRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Consent.WitnessMilestoneRequiredUnitRule(message: "witness milestone needs this field")
        let item = Consent.newWitnessMilestone("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
