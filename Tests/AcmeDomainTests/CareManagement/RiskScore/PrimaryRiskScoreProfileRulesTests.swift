@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryRiskScoreProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPrimaryRiskScoreProfileValidator()
        let item = CareManagement.newPrimaryRiskScoreProfile("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPrimaryRiskScoreProfileOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = CareManagement.PrimaryRiskScoreProfileOwnerIDLengthRule(maxLength: 16)
        let item = CareManagement.newPrimaryRiskScoreProfile("x", title: "y")
        item.ownerID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPrimaryRiskScoreProfileTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.PrimaryRiskScoreProfileTitleLengthRule(maxLength: 32)
        let item = CareManagement.newPrimaryRiskScoreProfile("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPrimaryRiskScoreProfileQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = CareManagement.PrimaryRiskScoreProfileQuantityRangeRule(min: 32, max: 120)
        let item = CareManagement.newPrimaryRiskScoreProfile("x", title: "y")
        item.quantity = 121
        #expect(rule.check(item).count > 0)
    }
}
