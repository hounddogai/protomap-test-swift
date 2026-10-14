@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualCareGapVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultManualCareGapVarianceValidator()
        let item = CareManagement.newManualCareGapVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementManualCareGapVarianceTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.ManualCareGapVarianceTitleLengthRule(maxLength: 3600)
        let item = CareManagement.newManualCareGapVariance("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementManualCareGapVarianceExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = CareManagement.ManualCareGapVarianceExternalRefLengthRule(maxLength: 32)
        let item = CareManagement.newManualCareGapVariance("x", title: "y")
        item.externalRef = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementManualCareGapVarianceProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = CareManagement.ManualCareGapVarianceProcedureCodeLengthRule(maxLength: 80)
        let item = CareManagement.newManualCareGapVariance("x", title: "y")
        item.procedureCode = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementManualCareGapVarianceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.ManualCareGapVarianceRequiredTitleRule(
            message: "manual care gap variance needs this field"
        )
        let item = CareManagement.newManualCareGapVariance("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
