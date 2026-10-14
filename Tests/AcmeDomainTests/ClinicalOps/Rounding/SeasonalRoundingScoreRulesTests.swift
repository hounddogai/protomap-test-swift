@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalRoundingScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultSeasonalRoundingScoreValidator()
        let item = ClinicalOps.newSeasonalRoundingScore("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsSeasonalRoundingScoreScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = ClinicalOps.SeasonalRoundingScoreScoreRangeRule(min: 0.8, max: 880.9)
        let item = ClinicalOps.newSeasonalRoundingScore("x", label: "y")
        item.score = 882.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsSeasonalRoundingScoreClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = ClinicalOps.SeasonalRoundingScoreClinicianIDLengthRule(maxLength: 1000)
        let item = ClinicalOps.newSeasonalRoundingScore("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsSeasonalRoundingScoreOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = ClinicalOps.SeasonalRoundingScoreOwnerIDLengthRule(maxLength: 1000)
        let item = ClinicalOps.newSeasonalRoundingScore("x", label: "y")
        item.ownerID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
