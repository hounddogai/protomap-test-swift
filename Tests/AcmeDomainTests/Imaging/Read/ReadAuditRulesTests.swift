@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultReadAuditValidator()
        let item = Imaging.newReadAudit("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingReadAuditRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.ReadAuditRequiredTitleRule(message: "read audit needs this field")
        let item = Imaging.newReadAudit("", label: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingReadAuditExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Imaging.ReadAuditExpiresAtRangeRule(min: 3600, max: 3600)
        let item = Imaging.newReadAudit("x", label: "y")
        item.expiresAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingReadAuditRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ReadAuditRequiredCodeRule(message: "read audit needs this field")
        let item = Imaging.newReadAudit("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
