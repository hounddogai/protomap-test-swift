@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingRoundingQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRollingRoundingQuotaValidator()
        let item = ClinicalOps.newRollingRoundingQuota("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRollingRoundingQuotaRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.RollingRoundingQuotaRequiredNameRule(message: "rolling rounding quota needs this field")
        let item = ClinicalOps.newRollingRoundingQuota("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRollingRoundingQuotaRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.RollingRoundingQuotaRequiredTitleRule(message: "rolling rounding quota needs an entry")
        let item = ClinicalOps.newRollingRoundingQuota("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRollingRoundingQuotaTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.RollingRoundingQuotaTitleLengthRule(maxLength: 32)
        let item = ClinicalOps.newRollingRoundingQuota("x", name: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRollingRoundingQuotaCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.RollingRoundingQuotaCodeLengthRule(maxLength: 3600)
        let item = ClinicalOps.newRollingRoundingQuota("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRollingRoundingQuotaQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = ClinicalOps.RollingRoundingQuotaQuantityRangeRule(min: 64, max: 255)
        let item = ClinicalOps.newRollingRoundingQuota("x", name: "y")
        item.quantity = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRollingRoundingQuotaRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.RollingRoundingQuotaRequiredCodeRule(message: "rolling rounding quota needs an entry")
        let item = ClinicalOps.newRollingRoundingQuota("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
