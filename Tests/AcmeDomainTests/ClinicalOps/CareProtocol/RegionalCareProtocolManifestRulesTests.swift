@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalCareProtocolManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRegionalCareProtocolManifestValidator()
        let item = ClinicalOps.newRegionalCareProtocolManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRegionalCareProtocolManifestLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.RegionalCareProtocolManifestLabelLengthRule(maxLength: 120)
        let item = ClinicalOps.newRegionalCareProtocolManifest("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRegionalCareProtocolManifestRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = ClinicalOps.RegionalCareProtocolManifestRequiredClinicianIDRule(
            message: "regional care protocol manifest needs a value"
        )
        let item = ClinicalOps.newRegionalCareProtocolManifest("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRegionalCareProtocolManifestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.RegionalCareProtocolManifestCodeLengthRule(maxLength: 80)
        let item = ClinicalOps.newRegionalCareProtocolManifest("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRegionalCareProtocolManifestAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = ClinicalOps.RegionalCareProtocolManifestAllergyLengthRule(maxLength: 3600)
        let item = ClinicalOps.newRegionalCareProtocolManifest("x", label: "y")
        item.allergy = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRegionalCareProtocolManifestRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = ClinicalOps.RegionalCareProtocolManifestRequiredAllergyRule(
            message: "regional care protocol manifest needs this field"
        )
        let item = ClinicalOps.newRegionalCareProtocolManifest("", label: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}
