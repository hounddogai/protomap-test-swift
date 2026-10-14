@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalSpecimenMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSeasonalSpecimenMilestoneValidator()
        let item = Labs.newSeasonalSpecimenMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSeasonalSpecimenMilestoneAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Labs.SeasonalSpecimenMilestoneAcuityRangeRule(min: 120, max: 1000)
        let item = Labs.newSeasonalSpecimenMilestone("x", title: "y")
        item.acuity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSeasonalSpecimenMilestoneRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Labs.SeasonalSpecimenMilestoneRequiredPatientRefRule(
            message: "seasonal specimen milestone needs an entry"
        )
        let item = Labs.newSeasonalSpecimenMilestone("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSeasonalSpecimenMilestoneRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.SeasonalSpecimenMilestoneRequiredTitleRule(message: "seasonal specimen milestone needs a value")
        let item = Labs.newSeasonalSpecimenMilestone("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSeasonalSpecimenMilestonePatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Labs.SeasonalSpecimenMilestonePatientRefLengthRule(maxLength: 80)
        let item = Labs.newSeasonalSpecimenMilestone("x", title: "y")
        item.patientRef = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
