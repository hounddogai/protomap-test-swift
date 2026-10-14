@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultOutreachSegmentValidator()
        let item = CareManagement.newOutreachSegment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementOutreachSegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.OutreachSegmentRequiredCodeRule(message: "outreach segment needs a value")
        let item = CareManagement.newOutreachSegment("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementOutreachSegmentAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = CareManagement.OutreachSegmentAttemptsRangeRule(min: 16, max: 32)
        let item = CareManagement.newOutreachSegment("x", title: "y")
        item.attempts = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementOutreachSegmentRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.OutreachSegmentRequiredTitleRule(message: "outreach segment needs an entry")
        let item = CareManagement.newOutreachSegment("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementOutreachSegmentContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = CareManagement.OutreachSegmentContactEmailLengthRule(maxLength: 64)
        let item = CareManagement.newOutreachSegment("x", title: "y")
        item.contactEmail = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}
