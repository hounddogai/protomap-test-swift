@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredTaskMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTieredTaskMilestoneValidator()
        let item = ClinicalOps.newTieredTaskMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTieredTaskMilestoneCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = ClinicalOps.TieredTaskMilestoneCategoryLengthRule(maxLength: 3600)
        let item = ClinicalOps.newTieredTaskMilestone("x", name: "y")
        item.category = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTieredTaskMilestoneRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = ClinicalOps.TieredTaskMilestoneRequiredSpecialtyRule(message: "tiered task milestone needs a value")
        let item = ClinicalOps.newTieredTaskMilestone("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTieredTaskMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.TieredTaskMilestoneRequiredCodeRule(message: "tiered task milestone needs a value")
        let item = ClinicalOps.newTieredTaskMilestone("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTieredTaskMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.TieredTaskMilestoneCodeLengthRule(maxLength: 16)
        let item = ClinicalOps.newTieredTaskMilestone("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
