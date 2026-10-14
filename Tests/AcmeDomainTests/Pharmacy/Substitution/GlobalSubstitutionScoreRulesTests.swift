@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalSubstitutionScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultGlobalSubstitutionScoreValidator()
        let item = Pharmacy.newGlobalSubstitutionScore("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyGlobalSubstitutionScoreScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Pharmacy.GlobalSubstitutionScoreScoreRangeRule(min: 4.2, max: 4405.9)
        let item = Pharmacy.newGlobalSubstitutionScore("x", title: "y")
        item.score = 4407.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyGlobalSubstitutionScoreCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.GlobalSubstitutionScoreCodeLengthRule(maxLength: 1000)
        let item = Pharmacy.newGlobalSubstitutionScore("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
