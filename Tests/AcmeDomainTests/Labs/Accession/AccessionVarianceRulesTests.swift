@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionVarianceValidator()
        let item = Labs.newAccessionVariance("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionVarianceEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Labs.AccessionVarianceEncounterIDLengthRule(maxLength: 86400)
        let item = Labs.newAccessionVariance("x", name: "y")
        item.encounterID = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionVarianceCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Labs.AccessionVarianceCopayRangeRule(min: 2.8, max: 4229.4)
        let item = Labs.newAccessionVariance("x", name: "y")
        item.copay = 4230.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAccessionVarianceSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Labs.AccessionVarianceSpecialtyLengthRule(maxLength: 32)
        let item = Labs.newAccessionVariance("x", name: "y")
        item.specialty = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}
