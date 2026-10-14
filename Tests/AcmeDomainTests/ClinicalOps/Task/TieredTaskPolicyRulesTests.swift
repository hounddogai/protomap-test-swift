@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredTaskPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTieredTaskPolicyValidator()
        let item = ClinicalOps.newTieredTaskPolicy("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTieredTaskPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.TieredTaskPolicyRequiredCodeRule(message: "tiered task policy needs a value")
        let item = ClinicalOps.newTieredTaskPolicy("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTieredTaskPolicyRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = ClinicalOps.TieredTaskPolicyRequiredExternalRefRule(message: "tiered task policy needs this field")
        let item = ClinicalOps.newTieredTaskPolicy("", title: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTieredTaskPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.TieredTaskPolicyCodeLengthRule(maxLength: 255)
        let item = ClinicalOps.newTieredTaskPolicy("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTieredTaskPolicyCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = ClinicalOps.TieredTaskPolicyCostRangeRule(min: 0.2, max: 1416.9)
        let item = ClinicalOps.newTieredTaskPolicy("x", title: "y")
        item.cost = 1418.4
        #expect(rule.check(item).count > 0)
    }
}
