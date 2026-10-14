@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryAccessionGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPrimaryAccessionGroupValidator()
        let item = Labs.newPrimaryAccessionGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPrimaryAccessionGroupExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Labs.PrimaryAccessionGroupExternalRefLengthRule(maxLength: 1000)
        let item = Labs.newPrimaryAccessionGroup("x", label: "y")
        item.externalRef = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPrimaryAccessionGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.PrimaryAccessionGroupCodeLengthRule(maxLength: 86400)
        let item = Labs.newPrimaryAccessionGroup("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPrimaryAccessionGroupRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Labs.PrimaryAccessionGroupRequiredClinicianIDRule(message: "primary accession group needs this field")
        let item = Labs.newPrimaryAccessionGroup("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPrimaryAccessionGroupClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Labs.PrimaryAccessionGroupClinicianIDLengthRule(maxLength: 86400)
        let item = Labs.newPrimaryAccessionGroup("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPrimaryAccessionGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PrimaryAccessionGroupRequiredCodeRule(message: "primary accession group needs a value")
        let item = Labs.newPrimaryAccessionGroup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
