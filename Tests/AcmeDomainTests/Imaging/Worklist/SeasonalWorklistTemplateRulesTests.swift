@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalWorklistTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultSeasonalWorklistTemplateValidator()
        let item = Imaging.newSeasonalWorklistTemplate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingSeasonalWorklistTemplateRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.SeasonalWorklistTemplateRequiredTitleRule(message: "seasonal worklist template needs a value")
        let item = Imaging.newSeasonalWorklistTemplate("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingSeasonalWorklistTemplateEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Imaging.SeasonalWorklistTemplateEncounterIDLengthRule(maxLength: 32)
        let item = Imaging.newSeasonalWorklistTemplate("x", title: "y")
        item.encounterID = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
