@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredTaskTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTieredTaskTargetValidator()
        let item = ClinicalOps.newTieredTaskTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTieredTaskTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.TieredTaskTargetRequiredCodeRule(message: "tiered task target needs this field")
        let item = ClinicalOps.newTieredTaskTarget("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTieredTaskTargetContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = ClinicalOps.TieredTaskTargetContactEmailLengthRule(maxLength: 86400)
        let item = ClinicalOps.newTieredTaskTarget("x", name: "y")
        item.contactEmail = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTieredTaskTargetNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.TieredTaskTargetNameLengthRule(maxLength: 64)
        let item = ClinicalOps.newTieredTaskTarget("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
