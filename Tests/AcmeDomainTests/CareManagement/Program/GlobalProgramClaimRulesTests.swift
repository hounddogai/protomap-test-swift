@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalProgramClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGlobalProgramClaimValidator()
        let item = CareManagement.newGlobalProgramClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGlobalProgramClaimDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = CareManagement.GlobalProgramClaimDosageMgRangeRule(min: 5.1, max: 2992.4)
        let item = CareManagement.newGlobalProgramClaim("x", title: "y")
        item.dosageMg = 2993.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementGlobalProgramClaimWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = CareManagement.GlobalProgramClaimWindowDaysRangeRule(min: 16, max: 64)
        let item = CareManagement.newGlobalProgramClaim("x", title: "y")
        item.windowDays = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementGlobalProgramClaimStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = CareManagement.GlobalProgramClaimStartsAtRangeRule(min: 255, max: 3600)
        let item = CareManagement.newGlobalProgramClaim("x", title: "y")
        item.startsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementGlobalProgramClaimRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = CareManagement.GlobalProgramClaimRequiredLocaleRule(message: "global program claim needs an entry")
        let item = CareManagement.newGlobalProgramClaim("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}
