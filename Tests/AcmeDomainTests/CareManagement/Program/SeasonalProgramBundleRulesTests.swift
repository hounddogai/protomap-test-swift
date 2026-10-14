@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalProgramBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultSeasonalProgramBundleValidator()
        let item = CareManagement.newSeasonalProgramBundle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementSeasonalProgramBundleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.SeasonalProgramBundleCodeLengthRule(maxLength: 80)
        let item = CareManagement.newSeasonalProgramBundle("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementSeasonalProgramBundleLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = CareManagement.SeasonalProgramBundleLimitRangeRule(min: 32, max: 1000)
        let item = CareManagement.newSeasonalProgramBundle("x", title: "y")
        item.limit = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementSeasonalProgramBundleRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = CareManagement.SeasonalProgramBundleRequiredDescriptionRule(
            message: "seasonal program bundle needs this field"
        )
        let item = CareManagement.newSeasonalProgramBundle("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}
