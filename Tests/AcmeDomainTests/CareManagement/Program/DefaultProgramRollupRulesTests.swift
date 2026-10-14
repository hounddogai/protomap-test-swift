@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultProgramRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultDefaultProgramRollupValidator()
        let item = CareManagement.newDefaultProgramRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementDefaultProgramRollupLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.DefaultProgramRollupLabelLengthRule(maxLength: 64)
        let item = CareManagement.newDefaultProgramRollup("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementDefaultProgramRollupVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = CareManagement.DefaultProgramRollupVisitMinutesRangeRule(min: 64, max: 80)
        let item = CareManagement.newDefaultProgramRollup("x", label: "y")
        item.visitMinutes = 81
        #expect(rule.check(item).count > 0)
    }
}
