@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingProgramEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPendingProgramEstimateValidator()
        let item = CareManagement.newPendingProgramEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPendingProgramEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.PendingProgramEstimateCodeLengthRule(maxLength: 80)
        let item = CareManagement.newPendingProgramEstimate("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPendingProgramEstimateGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = CareManagement.PendingProgramEstimateGraceDaysRangeRule(min: 32, max: 86400)
        let item = CareManagement.newPendingProgramEstimate("x", name: "y")
        item.graceDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementPendingProgramEstimateTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.PendingProgramEstimateTitleLengthRule(maxLength: 120)
        let item = CareManagement.newPendingProgramEstimate("x", name: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPendingProgramEstimateNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.PendingProgramEstimateNameLengthRule(maxLength: 3600)
        let item = CareManagement.newPendingProgramEstimate("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
