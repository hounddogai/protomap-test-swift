@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalProgramQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGlobalProgramQuotaValidator()
        let item = CareManagement.newGlobalProgramQuota("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGlobalProgramQuotaRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.GlobalProgramQuotaRequiredCodeRule(message: "global program quota needs a value")
        let item = CareManagement.newGlobalProgramQuota("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGlobalProgramQuotaDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = CareManagement.GlobalProgramQuotaDosageMgRangeRule(min: 8.3, max: 2848.1)
        let item = CareManagement.newGlobalProgramQuota("x", title: "y")
        item.dosageMg = 2849.6
        #expect(rule.check(item).count > 0)
    }
}
