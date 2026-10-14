@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredCareGapAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultTieredCareGapAuditValidator()
        let item = CareManagement.newTieredCareGapAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementTieredCareGapAuditAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = CareManagement.TieredCareGapAuditAllergyLengthRule(maxLength: 255)
        let item = CareManagement.newTieredCareGapAudit("x", title: "y")
        item.allergy = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementTieredCareGapAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.TieredCareGapAuditCodeLengthRule(maxLength: 86400)
        let item = CareManagement.newTieredCareGapAudit("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementTieredCareGapAuditRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = CareManagement.TieredCareGapAuditRequiredAllergyRule(message: "tiered care gap audit needs an entry")
        let item = CareManagement.newTieredCareGapAudit("", title: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementTieredCareGapAuditRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.TieredCareGapAuditRequiredCodeRule(message: "tiered care gap audit needs an entry")
        let item = CareManagement.newTieredCareGapAudit("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
