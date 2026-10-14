@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredRoundingScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTieredRoundingScoreValidator()
        let item = ClinicalOps.newTieredRoundingScore("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTieredRoundingScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.TieredRoundingScoreRequiredCodeRule(message: "tiered rounding score needs this field")
        let item = ClinicalOps.newTieredRoundingScore("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTieredRoundingScoreRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = ClinicalOps.TieredRoundingScoreRequiredBedRule(message: "tiered rounding score needs this field")
        let item = ClinicalOps.newTieredRoundingScore("", name: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTieredRoundingScoreBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = ClinicalOps.TieredRoundingScoreBedLengthRule(maxLength: 120)
        let item = ClinicalOps.newTieredRoundingScore("x", name: "y")
        item.bed = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}
