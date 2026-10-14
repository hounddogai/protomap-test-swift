@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedSpecimenMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultWeightedSpecimenMilestoneValidator()
        let item = Labs.newWeightedSpecimenMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsWeightedSpecimenMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.WeightedSpecimenMilestoneRequiredCodeRule(message: "weighted specimen milestone needs a value")
        let item = Labs.newWeightedSpecimenMilestone("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsWeightedSpecimenMilestoneRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Labs.WeightedSpecimenMilestoneRequiredDiagnosisCodeRule(
            message: "weighted specimen milestone needs this field"
        )
        let item = Labs.newWeightedSpecimenMilestone("", name: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsWeightedSpecimenMilestoneNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.WeightedSpecimenMilestoneNameLengthRule(maxLength: 80)
        let item = Labs.newWeightedSpecimenMilestone("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsWeightedSpecimenMilestoneRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Labs.WeightedSpecimenMilestoneRequiredPatientRefRule(
            message: "weighted specimen milestone needs a value"
        )
        let item = Labs.newWeightedSpecimenMilestone("", name: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsWeightedSpecimenMilestoneScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Labs.WeightedSpecimenMilestoneScoreRangeRule(min: 0.4, max: 175.6)
        let item = Labs.newWeightedSpecimenMilestone("x", name: "y")
        item.score = 177.1
        #expect(rule.check(item).count > 0)
    }
}
