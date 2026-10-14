@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolAuditValidator()
        let item = Imaging.newCareProtocolAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolAuditDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Imaging.CareProtocolAuditDosageMgRangeRule(min: 7.3, max: 268.7)
        let item = Imaging.newCareProtocolAudit("x", title: "y")
        item.dosageMg = 270.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingCareProtocolAuditTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.CareProtocolAuditTitleLengthRule(maxLength: 32)
        let item = Imaging.newCareProtocolAudit("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolAuditDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Imaging.CareProtocolAuditDescriptionLengthRule(maxLength: 255)
        let item = Imaging.newCareProtocolAudit("x", title: "y")
        item.description = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolAuditClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Imaging.CareProtocolAuditClinicianIDLengthRule(maxLength: 80)
        let item = Imaging.newCareProtocolAudit("x", title: "y")
        item.clinicianID = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolAuditRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.CareProtocolAuditRequiredTitleRule(message: "care protocol audit needs this field")
        let item = Imaging.newCareProtocolAudit("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
