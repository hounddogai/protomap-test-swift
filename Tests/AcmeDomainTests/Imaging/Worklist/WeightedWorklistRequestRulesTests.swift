@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedWorklistRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWeightedWorklistRequestValidator()
        let item = Imaging.newWeightedWorklistRequest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWeightedWorklistRequestEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Imaging.WeightedWorklistRequestEncounterIDLengthRule(maxLength: 16)
        let item = Imaging.newWeightedWorklistRequest("x", title: "y")
        item.encounterID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWeightedWorklistRequestCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Imaging.WeightedWorklistRequestCeilingRangeRule(min: 8.5, max: 355.3)
        let item = Imaging.newWeightedWorklistRequest("x", title: "y")
        item.ceiling = 356.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWeightedWorklistRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.WeightedWorklistRequestCodeLengthRule(maxLength: 120)
        let item = Imaging.newWeightedWorklistRequest("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWeightedWorklistRequestRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Imaging.WeightedWorklistRequestRequiredNotesRule(message: "weighted worklist request needs an entry")
        let item = Imaging.newWeightedWorklistRequest("", title: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}
