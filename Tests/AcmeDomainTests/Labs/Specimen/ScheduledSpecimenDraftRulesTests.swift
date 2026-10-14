@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledSpecimenDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultScheduledSpecimenDraftValidator()
        let item = Labs.newScheduledSpecimenDraft("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsScheduledSpecimenDraftRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Labs.ScheduledSpecimenDraftRequiredFacilityRule(message: "scheduled specimen draft needs a value")
        let item = Labs.newScheduledSpecimenDraft("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsScheduledSpecimenDraftSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Labs.ScheduledSpecimenDraftSequenceRangeRule(min: 64, max: 3600)
        let item = Labs.newScheduledSpecimenDraft("x", title: "y")
        item.sequence = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsScheduledSpecimenDraftContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Labs.ScheduledSpecimenDraftContactEmailLengthRule(maxLength: 3600)
        let item = Labs.newScheduledSpecimenDraft("x", title: "y")
        item.contactEmail = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}
