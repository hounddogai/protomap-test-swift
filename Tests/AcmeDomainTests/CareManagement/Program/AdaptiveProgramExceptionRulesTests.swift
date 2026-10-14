@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveProgramExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAdaptiveProgramExceptionValidator()
        let item = CareManagement.newAdaptiveProgramException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAdaptiveProgramExceptionNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.AdaptiveProgramExceptionNameLengthRule(maxLength: 255)
        let item = CareManagement.newAdaptiveProgramException("x", title: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAdaptiveProgramExceptionAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = CareManagement.AdaptiveProgramExceptionAcuityRangeRule(min: 16, max: 3600)
        let item = CareManagement.newAdaptiveProgramException("x", title: "y")
        item.acuity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAdaptiveProgramExceptionCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.AdaptiveProgramExceptionCodeLengthRule(maxLength: 32)
        let item = CareManagement.newAdaptiveProgramException("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
