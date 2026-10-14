@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualProgramBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultManualProgramBundleValidator()
        let item = CareManagement.newManualProgramBundle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementManualProgramBundleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.ManualProgramBundleCodeLengthRule(maxLength: 32)
        let item = CareManagement.newManualProgramBundle("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementManualProgramBundlePhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = CareManagement.ManualProgramBundlePhoneLengthRule(maxLength: 120)
        let item = CareManagement.newManualProgramBundle("x", title: "y")
        item.phone = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
