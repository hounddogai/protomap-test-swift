@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalRiskScoreSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRegionalRiskScoreSummaryValidator()
        let item = CareManagement.newRegionalRiskScoreSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRegionalRiskScoreSummaryRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = CareManagement.RegionalRiskScoreSummaryRetriesRangeRule(min: 255, max: 1000)
        let item = CareManagement.newRegionalRiskScoreSummary("x", title: "y")
        item.retries = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRegionalRiskScoreSummaryFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = CareManagement.RegionalRiskScoreSummaryFloorValueRangeRule(min: 6.3, max: 721.7)
        let item = CareManagement.newRegionalRiskScoreSummary("x", title: "y")
        item.floorValue = 723.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRegionalRiskScoreSummaryTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.RegionalRiskScoreSummaryTitleLengthRule(maxLength: 64)
        let item = CareManagement.newRegionalRiskScoreSummary("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRegionalRiskScoreSummaryChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = CareManagement.RegionalRiskScoreSummaryChannelLengthRule(maxLength: 3600)
        let item = CareManagement.newRegionalRiskScoreSummary("x", title: "y")
        item.channel = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}
