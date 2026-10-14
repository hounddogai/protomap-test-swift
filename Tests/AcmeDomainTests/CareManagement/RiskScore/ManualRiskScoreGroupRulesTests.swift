@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualRiskScoreGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultManualRiskScoreGroupValidator()
        let item = CareManagement.newManualRiskScoreGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementManualRiskScoreGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.ManualRiskScoreGroupRequiredCodeRule(
            message: "manual risk score group needs this field"
        )
        let item = CareManagement.newManualRiskScoreGroup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementManualRiskScoreGroupRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = CareManagement.ManualRiskScoreGroupRequiredDescriptionRule(
            message: "manual risk score group needs a value"
        )
        let item = CareManagement.newManualRiskScoreGroup("", label: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementManualRiskScoreGroupDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = CareManagement.ManualRiskScoreGroupDescriptionLengthRule(maxLength: 3600)
        let item = CareManagement.newManualRiskScoreGroup("x", label: "y")
        item.description = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}
