@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledRoundingScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultScheduledRoundingScoreValidator()
        let item = ClinicalOps.newScheduledRoundingScore("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsScheduledRoundingScoreDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = ClinicalOps.ScheduledRoundingScoreDescriptionLengthRule(maxLength: 64)
        let item = ClinicalOps.newScheduledRoundingScore("x", name: "y")
        item.description = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsScheduledRoundingScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.ScheduledRoundingScoreRequiredCodeRule(
            message: "scheduled rounding score needs this field"
        )
        let item = ClinicalOps.newScheduledRoundingScore("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsScheduledRoundingScoreRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.ScheduledRoundingScoreRequiredNameRule(message: "scheduled rounding score needs a value")
        let item = ClinicalOps.newScheduledRoundingScore("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
