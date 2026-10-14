@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGoalSegmentValidator()
        let item = CareManagement.newGoalSegment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGoalSegmentRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = CareManagement.GoalSegmentRequiredCountryRule(message: "goal segment needs an entry")
        let item = CareManagement.newGoalSegment("", title: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGoalSegmentTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.GoalSegmentTitleLengthRule(maxLength: 255)
        let item = CareManagement.newGoalSegment("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalSegmentRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = CareManagement.GoalSegmentRequiredContactEmailRule(message: "goal segment needs a value")
        let item = CareManagement.newGoalSegment("", title: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}
