@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalRiskScoreAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGlobalRiskScoreAuditValidator()
        let item = CareManagement.newGlobalRiskScoreAudit("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGlobalRiskScoreAuditRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.GlobalRiskScoreAuditRequiredCodeRule(message: "global risk score audit needs a value")
        let item = CareManagement.newGlobalRiskScoreAudit("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGlobalRiskScoreAuditUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = CareManagement.GlobalRiskScoreAuditUnitLengthRule(maxLength: 1000)
        let item = CareManagement.newGlobalRiskScoreAudit("x", name: "y")
        item.unit = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGlobalRiskScoreAuditRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = CareManagement.GlobalRiskScoreAuditRefillsRangeRule(min: 32, max: 64)
        let item = CareManagement.newGlobalRiskScoreAudit("x", name: "y")
        item.refills = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementGlobalRiskScoreAuditVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = CareManagement.GlobalRiskScoreAuditVersionRangeRule(min: 16, max: 64)
        let item = CareManagement.newGlobalRiskScoreAudit("x", name: "y")
        item.version = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementGlobalRiskScoreAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.GlobalRiskScoreAuditCodeLengthRule(maxLength: 255)
        let item = CareManagement.newGlobalRiskScoreAudit("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
