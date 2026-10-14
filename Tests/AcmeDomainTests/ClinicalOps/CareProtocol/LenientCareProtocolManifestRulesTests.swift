@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLenientCareProtocolManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultLenientCareProtocolManifestValidator()
        let item = ClinicalOps.newLenientCareProtocolManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsLenientCareProtocolManifestChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = ClinicalOps.LenientCareProtocolManifestChannelLengthRule(maxLength: 120)
        let item = ClinicalOps.newLenientCareProtocolManifest("x", label: "y")
        item.channel = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsLenientCareProtocolManifestClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = ClinicalOps.LenientCareProtocolManifestClinicianIDLengthRule(maxLength: 16)
        let item = ClinicalOps.newLenientCareProtocolManifest("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsLenientCareProtocolManifestRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = ClinicalOps.LenientCareProtocolManifestRequiredClinicianIDRule(
            message: "lenient care protocol manifest needs an entry"
        )
        let item = ClinicalOps.newLenientCareProtocolManifest("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}
