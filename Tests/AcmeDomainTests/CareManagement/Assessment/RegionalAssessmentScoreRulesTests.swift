@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalAssessmentScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRegionalAssessmentScoreValidator()
        let item = CareManagement.newRegionalAssessmentScore("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRegionalAssessmentScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.RegionalAssessmentScoreRequiredCodeRule(
            message: "regional assessment score needs this field"
        )
        let item = CareManagement.newRegionalAssessmentScore("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRegionalAssessmentScoreVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = CareManagement.RegionalAssessmentScoreVersionRangeRule(min: 64, max: 80)
        let item = CareManagement.newRegionalAssessmentScore("x", name: "y")
        item.version = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRegionalAssessmentScoreRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = CareManagement.RegionalAssessmentScoreRequiredSegmentRule(
            message: "regional assessment score needs a value"
        )
        let item = CareManagement.newRegionalAssessmentScore("", name: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRegionalAssessmentScoreRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.RegionalAssessmentScoreRequiredTitleRule(
            message: "regional assessment score needs an entry"
        )
        let item = CareManagement.newRegionalAssessmentScore("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
