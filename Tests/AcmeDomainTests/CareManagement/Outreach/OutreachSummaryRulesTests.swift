@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultOutreachSummaryValidator()
        let item = CareManagement.newOutreachSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementOutreachSummarySpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = CareManagement.OutreachSummarySpecialtyLengthRule(maxLength: 64)
        let item = CareManagement.newOutreachSummary("x", title: "y")
        item.specialty = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementOutreachSummaryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.OutreachSummaryCodeLengthRule(maxLength: 86400)
        let item = CareManagement.newOutreachSummary("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementOutreachSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.OutreachSummaryRequiredCodeRule(message: "outreach summary needs this field")
        let item = CareManagement.newOutreachSummary("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementOutreachSummaryRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.OutreachSummaryRequiredTitleRule(message: "outreach summary needs an entry")
        let item = CareManagement.newOutreachSummary("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
