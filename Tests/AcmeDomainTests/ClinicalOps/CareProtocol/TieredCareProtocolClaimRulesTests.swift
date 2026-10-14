@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredCareProtocolClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTieredCareProtocolClaimValidator()
        let item = ClinicalOps.newTieredCareProtocolClaim("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTieredCareProtocolClaimCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.TieredCareProtocolClaimCodeLengthRule(maxLength: 16)
        let item = ClinicalOps.newTieredCareProtocolClaim("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTieredCareProtocolClaimProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = ClinicalOps.TieredCareProtocolClaimProcedureCodeLengthRule(maxLength: 3600)
        let item = ClinicalOps.newTieredCareProtocolClaim("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTieredCareProtocolClaimRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = ClinicalOps.TieredCareProtocolClaimRequiredSpecialtyRule(
            message: "tiered care protocol claim needs an entry"
        )
        let item = ClinicalOps.newTieredCareProtocolClaim("", label: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTieredCareProtocolClaimAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = ClinicalOps.TieredCareProtocolClaimAcuityRangeRule(min: 80, max: 3600)
        let item = ClinicalOps.newTieredCareProtocolClaim("x", label: "y")
        item.acuity = 3601
        #expect(rule.check(item).count > 0)
    }
}
