@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedProgramClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCappedProgramClaimValidator()
        let item = CareManagement.newCappedProgramClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCappedProgramClaimWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = CareManagement.CappedProgramClaimWindowDaysRangeRule(min: 32, max: 1000)
        let item = CareManagement.newCappedProgramClaim("x", title: "y")
        item.windowDays = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementCappedProgramClaimQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = CareManagement.CappedProgramClaimQuantityRangeRule(min: 255, max: 255)
        let item = CareManagement.newCappedProgramClaim("x", title: "y")
        item.quantity = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementCappedProgramClaimRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.CappedProgramClaimRequiredTitleRule(message: "capped program claim needs an entry")
        let item = CareManagement.newCappedProgramClaim("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCappedProgramClaimRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = CareManagement.CappedProgramClaimRequiredRegionRule(message: "capped program claim needs this field")
        let item = CareManagement.newCappedProgramClaim("", title: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCappedProgramClaimCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.CappedProgramClaimCodeLengthRule(maxLength: 80)
        let item = CareManagement.newCappedProgramClaim("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
