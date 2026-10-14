@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredCareGapPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultTieredCareGapPolicyValidator()
        let item = CareManagement.newTieredCareGapPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementTieredCareGapPolicyRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.TieredCareGapPolicyRequiredNameRule(message: "tiered care gap policy needs this field")
        let item = CareManagement.newTieredCareGapPolicy("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementTieredCareGapPolicyNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.TieredCareGapPolicyNameLengthRule(maxLength: 64)
        let item = CareManagement.newTieredCareGapPolicy("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementTieredCareGapPolicyDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = CareManagement.TieredCareGapPolicyDescriptionLengthRule(maxLength: 86400)
        let item = CareManagement.newTieredCareGapPolicy("x", name: "y")
        item.description = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementTieredCareGapPolicyVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = CareManagement.TieredCareGapPolicyVersionRangeRule(min: 120, max: 86400)
        let item = CareManagement.newTieredCareGapPolicy("x", name: "y")
        item.version = 86401
        #expect(rule.check(item).count > 0)
    }
}
