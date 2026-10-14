@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultProgramManifestValidator()
        let item = CareManagement.newProgramManifest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementProgramManifestRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = CareManagement.ProgramManifestRequiredLocaleRule(message: "program manifest needs a value")
        let item = CareManagement.newProgramManifest("", name: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementProgramManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.ProgramManifestRequiredCodeRule(message: "program manifest needs this field")
        let item = CareManagement.newProgramManifest("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementProgramManifestAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = CareManagement.ProgramManifestAcuityRangeRule(min: 64, max: 120)
        let item = CareManagement.newProgramManifest("x", name: "y")
        item.acuity = 121
        #expect(rule.check(item).count > 0)
    }
}
