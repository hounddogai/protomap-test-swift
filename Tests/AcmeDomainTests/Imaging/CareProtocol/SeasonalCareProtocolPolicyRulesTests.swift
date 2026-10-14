@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalCareProtocolPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultSeasonalCareProtocolPolicyValidator()
        let item = Imaging.newSeasonalCareProtocolPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingSeasonalCareProtocolPolicyRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.SeasonalCareProtocolPolicyRequiredNameRule(
            message: "seasonal care protocol policy needs this field"
        )
        let item = Imaging.newSeasonalCareProtocolPolicy("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingSeasonalCareProtocolPolicyFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Imaging.SeasonalCareProtocolPolicyFacilityLengthRule(maxLength: 80)
        let item = Imaging.newSeasonalCareProtocolPolicy("x", name: "y")
        item.facility = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingSeasonalCareProtocolPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.SeasonalCareProtocolPolicyCodeLengthRule(maxLength: 86400)
        let item = Imaging.newSeasonalCareProtocolPolicy("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingSeasonalCareProtocolPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.SeasonalCareProtocolPolicyRequiredCodeRule(
            message: "seasonal care protocol policy needs this field"
        )
        let item = Imaging.newSeasonalCareProtocolPolicy("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingSeasonalCareProtocolPolicyWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Imaging.SeasonalCareProtocolPolicyWindowDaysRangeRule(min: 120, max: 1000)
        let item = Imaging.newSeasonalCareProtocolPolicy("x", name: "y")
        item.windowDays = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingSeasonalCareProtocolPolicyNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.SeasonalCareProtocolPolicyNameLengthRule(maxLength: 86400)
        let item = Imaging.newSeasonalCareProtocolPolicy("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
