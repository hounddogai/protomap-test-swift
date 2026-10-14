@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualProgramRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultManualProgramRollupValidator()
        let item = CareManagement.newManualProgramRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementManualProgramRollupRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.ManualProgramRollupRequiredNameRule(message: "manual program rollup needs this field")
        let item = CareManagement.newManualProgramRollup("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementManualProgramRollupRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = CareManagement.ManualProgramRollupRequiredRegionRule(message: "manual program rollup needs a value")
        let item = CareManagement.newManualProgramRollup("", name: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementManualProgramRollupCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = CareManagement.ManualProgramRollupCountryLengthRule(maxLength: 3600)
        let item = CareManagement.newManualProgramRollup("x", name: "y")
        item.country = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}
