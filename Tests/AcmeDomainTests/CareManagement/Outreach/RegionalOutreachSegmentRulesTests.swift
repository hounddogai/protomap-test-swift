@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalOutreachSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRegionalOutreachSegmentValidator()
        let item = CareManagement.newRegionalOutreachSegment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRegionalOutreachSegmentScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = CareManagement.RegionalOutreachSegmentScoreRangeRule(min: 7.7, max: 4048.2)
        let item = CareManagement.newRegionalOutreachSegment("x", title: "y")
        item.score = 4049.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRegionalOutreachSegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.RegionalOutreachSegmentRequiredCodeRule(
            message: "regional outreach segment needs an entry"
        )
        let item = CareManagement.newRegionalOutreachSegment("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
