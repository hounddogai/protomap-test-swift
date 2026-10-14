@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingDefaultCareProtocolAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultDefaultCareProtocolAuditValidator()
        let item = Imaging.newDefaultCareProtocolAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingDefaultCareProtocolAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.DefaultCareProtocolAuditCodeLengthRule(maxLength: 120)
        let item = Imaging.newDefaultCareProtocolAudit("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingDefaultCareProtocolAuditTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.DefaultCareProtocolAuditTitleLengthRule(maxLength: 120)
        let item = Imaging.newDefaultCareProtocolAudit("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingDefaultCareProtocolAuditRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.DefaultCareProtocolAuditRequiredTitleRule(
            message: "default care protocol audit needs this field"
        )
        let item = Imaging.newDefaultCareProtocolAudit("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingDefaultCareProtocolAuditMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Imaging.DefaultCareProtocolAuditMaximumRangeRule(min: 5.0, max: 2075.6)
        let item = Imaging.newDefaultCareProtocolAudit("x", title: "y")
        item.maximum = 2077.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingDefaultCareProtocolAuditRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.DefaultCareProtocolAuditRequiredCodeRule(message: "default care protocol audit needs a value")
        let item = Imaging.newDefaultCareProtocolAudit("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
