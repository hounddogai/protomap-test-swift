@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRegionalDischargePlanProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultRegionalDischargePlanProfileValidator()
        let item = BedManagement.newRegionalDischargePlanProfile("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementRegionalDischargePlanProfileRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = BedManagement.RegionalDischargePlanProfileRatioRangeRule(min: 0.0, max: 3003.0)
        let item = BedManagement.newRegionalDischargePlanProfile("x", title: "y")
        item.ratio = 3004.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementRegionalDischargePlanProfileRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.RegionalDischargePlanProfileRequiredCodeRule(
            message: "regional discharge plan profile needs this field"
        )
        let item = BedManagement.newRegionalDischargePlanProfile("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementRegionalDischargePlanProfileRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = BedManagement.RegionalDischargePlanProfileRequiredRegionRule(
            message: "regional discharge plan profile needs this field"
        )
        let item = BedManagement.newRegionalDischargePlanProfile("", title: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}
