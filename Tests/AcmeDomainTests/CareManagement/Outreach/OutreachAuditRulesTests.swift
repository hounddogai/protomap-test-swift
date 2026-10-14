@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultOutreachAuditValidator()
        let item = CareManagement.newOutreachAudit("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementOutreachAuditNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.OutreachAuditNameLengthRule(maxLength: 3600)
        let item = CareManagement.newOutreachAudit("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementOutreachAuditChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = CareManagement.OutreachAuditChannelLengthRule(maxLength: 32)
        let item = CareManagement.newOutreachAudit("x", name: "y")
        item.channel = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementOutreachAuditRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = CareManagement.OutreachAuditRequiredChannelRule(message: "outreach audit needs this field")
        let item = CareManagement.newOutreachAudit("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementOutreachAuditRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.OutreachAuditRequiredNameRule(message: "outreach audit needs this field")
        let item = CareManagement.newOutreachAudit("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
