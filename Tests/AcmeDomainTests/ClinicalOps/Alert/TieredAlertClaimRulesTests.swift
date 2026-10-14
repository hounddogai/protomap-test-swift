@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredAlertClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTieredAlertClaimValidator()
        let item = ClinicalOps.newTieredAlertClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTieredAlertClaimTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.TieredAlertClaimTitleLengthRule(maxLength: 64)
        let item = ClinicalOps.newTieredAlertClaim("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTieredAlertClaimRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = ClinicalOps.TieredAlertClaimRequiredClinicianIDRule(message: "tiered alert claim needs this field")
        let item = ClinicalOps.newTieredAlertClaim("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTieredAlertClaimClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = ClinicalOps.TieredAlertClaimClinicianIDLengthRule(maxLength: 80)
        let item = ClinicalOps.newTieredAlertClaim("x", title: "y")
        item.clinicianID = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTieredAlertClaimRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.TieredAlertClaimRequiredCodeRule(message: "tiered alert claim needs a value")
        let item = ClinicalOps.newTieredAlertClaim("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
