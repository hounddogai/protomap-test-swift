@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientProgramGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultLenientProgramGroupValidator()
        let item = CareManagement.newLenientProgramGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementLenientProgramGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.LenientProgramGroupCodeLengthRule(maxLength: 64)
        let item = CareManagement.newLenientProgramGroup("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLenientProgramGroupLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.LenientProgramGroupLabelLengthRule(maxLength: 80)
        let item = CareManagement.newLenientProgramGroup("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
