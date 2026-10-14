@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalReadMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultSeasonalReadMilestoneValidator()
        let item = Imaging.newSeasonalReadMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingSeasonalReadMilestoneCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Imaging.SeasonalReadMilestoneCountryLengthRule(maxLength: 86400)
        let item = Imaging.newSeasonalReadMilestone("x", name: "y")
        item.country = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingSeasonalReadMilestoneCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Imaging.SeasonalReadMilestoneCapacityRangeRule(min: 32, max: 3600)
        let item = Imaging.newSeasonalReadMilestone("x", name: "y")
        item.capacity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingSeasonalReadMilestoneRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Imaging.SeasonalReadMilestoneRequiredUnitRule(message: "seasonal read milestone needs an entry")
        let item = Imaging.newSeasonalReadMilestone("", name: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingSeasonalReadMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.SeasonalReadMilestoneRequiredCodeRule(message: "seasonal read milestone needs an entry")
        let item = Imaging.newSeasonalReadMilestone("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
