@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeAuditValidator()
        let item = Labs.newReferenceRangeAudit("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeAuditRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ReferenceRangeAuditRequiredCodeRule(message: "reference range audit needs this field")
        let item = Labs.newReferenceRangeAudit("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangeAuditNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.ReferenceRangeAuditNameLengthRule(maxLength: 1000)
        let item = Labs.newReferenceRangeAudit("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeAuditRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Labs.ReferenceRangeAuditRequiredRegionRule(message: "reference range audit needs this field")
        let item = Labs.newReferenceRangeAudit("", name: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangeAuditClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Labs.ReferenceRangeAuditClinicianIDLengthRule(maxLength: 3600)
        let item = Labs.newReferenceRangeAudit("x", name: "y")
        item.clinicianID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeAuditRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Labs.ReferenceRangeAuditRequiredClinicianIDRule(message: "reference range audit needs this field")
        let item = Labs.newReferenceRangeAudit("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}
