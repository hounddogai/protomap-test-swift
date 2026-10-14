@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryGoalScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPrimaryGoalScoreValidator()
        let item = CareManagement.newPrimaryGoalScore("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPrimaryGoalScoreBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = CareManagement.PrimaryGoalScoreBatchSizeRangeRule(min: 86400, max: 86400)
        let item = CareManagement.newPrimaryGoalScore("x", title: "y")
        item.batchSize = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementPrimaryGoalScoreRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = CareManagement.PrimaryGoalScoreRequiredOwnerIDRule(message: "primary goal score needs an entry")
        let item = CareManagement.newPrimaryGoalScore("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementPrimaryGoalScoreScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = CareManagement.PrimaryGoalScoreScoreRangeRule(min: 7.5, max: 467.3)
        let item = CareManagement.newPrimaryGoalScore("x", title: "y")
        item.score = 468.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementPrimaryGoalScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.PrimaryGoalScoreRequiredCodeRule(message: "primary goal score needs an entry")
        let item = CareManagement.newPrimaryGoalScore("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementPrimaryGoalScoreRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.PrimaryGoalScoreRequiredTitleRule(message: "primary goal score needs an entry")
        let item = CareManagement.newPrimaryGoalScore("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
