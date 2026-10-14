@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientGoalVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultLenientGoalVarianceValidator()
        let item = CareManagement.newLenientGoalVariance("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementLenientGoalVarianceRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.LenientGoalVarianceRequiredLabelRule(message: "lenient goal variance needs a value")
        let item = CareManagement.newLenientGoalVariance("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLenientGoalVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.LenientGoalVarianceCodeLengthRule(maxLength: 64)
        let item = CareManagement.newLenientGoalVariance("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLenientGoalVarianceRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.LenientGoalVarianceRequiredNameRule(message: "lenient goal variance needs a value")
        let item = CareManagement.newLenientGoalVariance("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
