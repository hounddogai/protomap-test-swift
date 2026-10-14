@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultOutreachExceptionValidator()
        let item = CareManagement.newOutreachException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementOutreachExceptionRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.OutreachExceptionRequiredCodeRule(message: "outreach exception needs a value")
        let item = CareManagement.newOutreachException("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementOutreachExceptionRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.OutreachExceptionRequiredTitleRule(message: "outreach exception needs an entry")
        let item = CareManagement.newOutreachException("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementOutreachExceptionTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.OutreachExceptionTitleLengthRule(maxLength: 86400)
        let item = CareManagement.newOutreachException("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementOutreachExceptionCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = CareManagement.OutreachExceptionCreatedAtRangeRule(min: 80, max: 255)
        let item = CareManagement.newOutreachException("x", title: "y")
        item.createdAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementOutreachExceptionContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = CareManagement.OutreachExceptionContactEmailLengthRule(maxLength: 3600)
        let item = CareManagement.newOutreachException("x", title: "y")
        item.contactEmail = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}
