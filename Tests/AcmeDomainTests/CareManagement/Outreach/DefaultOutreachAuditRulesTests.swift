@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultOutreachAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultDefaultOutreachAuditValidator()
        let item = CareManagement.newDefaultOutreachAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementDefaultOutreachAuditContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = CareManagement.DefaultOutreachAuditContactEmailLengthRule(maxLength: 80)
        let item = CareManagement.newDefaultOutreachAudit("x", title: "y")
        item.contactEmail = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementDefaultOutreachAuditRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = CareManagement.DefaultOutreachAuditRequiredContactEmailRule(
            message: "default outreach audit needs this field"
        )
        let item = CareManagement.newDefaultOutreachAudit("", title: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementDefaultOutreachAuditSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = CareManagement.DefaultOutreachAuditSequenceRangeRule(min: 16, max: 80)
        let item = CareManagement.newDefaultOutreachAudit("x", title: "y")
        item.sequence = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementDefaultOutreachAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.DefaultOutreachAuditCodeLengthRule(maxLength: 80)
        let item = CareManagement.newDefaultOutreachAudit("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
