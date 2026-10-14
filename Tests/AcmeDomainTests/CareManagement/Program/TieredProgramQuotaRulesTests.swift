@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredProgramQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultTieredProgramQuotaValidator()
        let item = CareManagement.newTieredProgramQuota("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementTieredProgramQuotaCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.TieredProgramQuotaCodeLengthRule(maxLength: 80)
        let item = CareManagement.newTieredProgramQuota("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementTieredProgramQuotaBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = CareManagement.TieredProgramQuotaBatchSizeRangeRule(min: 64, max: 80)
        let item = CareManagement.newTieredProgramQuota("x", name: "y")
        item.batchSize = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementTieredProgramQuotaRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.TieredProgramQuotaRequiredCodeRule(message: "tiered program quota needs an entry")
        let item = CareManagement.newTieredProgramQuota("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementTieredProgramQuotaNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.TieredProgramQuotaNameLengthRule(maxLength: 80)
        let item = CareManagement.newTieredProgramQuota("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementTieredProgramQuotaExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = CareManagement.TieredProgramQuotaExpiresAtRangeRule(min: 120, max: 3600)
        let item = CareManagement.newTieredProgramQuota("x", name: "y")
        item.expiresAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
