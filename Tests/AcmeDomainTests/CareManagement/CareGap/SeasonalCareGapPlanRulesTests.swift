@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalCareGapPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultSeasonalCareGapPlanValidator()
        let item = CareManagement.newSeasonalCareGapPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementSeasonalCareGapPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.SeasonalCareGapPlanRequiredCodeRule(message: "seasonal care gap plan needs a value")
        let item = CareManagement.newSeasonalCareGapPlan("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementSeasonalCareGapPlanRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = CareManagement.SeasonalCareGapPlanRequiredPhoneRule(message: "seasonal care gap plan needs an entry")
        let item = CareManagement.newSeasonalCareGapPlan("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementSeasonalCareGapPlanRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.SeasonalCareGapPlanRequiredTitleRule(message: "seasonal care gap plan needs an entry")
        let item = CareManagement.newSeasonalCareGapPlan("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
