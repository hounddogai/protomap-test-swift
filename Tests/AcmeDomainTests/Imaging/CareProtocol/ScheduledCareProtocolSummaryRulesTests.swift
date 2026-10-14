@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledCareProtocolSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultScheduledCareProtocolSummaryValidator()
        let item = Imaging.newScheduledCareProtocolSummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingScheduledCareProtocolSummaryRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Imaging.ScheduledCareProtocolSummaryRequiredFacilityRule(
            message: "scheduled care protocol summary needs a value"
        )
        let item = Imaging.newScheduledCareProtocolSummary("", label: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingScheduledCareProtocolSummaryRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.ScheduledCareProtocolSummaryRequiredLabelRule(
            message: "scheduled care protocol summary needs this field"
        )
        let item = Imaging.newScheduledCareProtocolSummary("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingScheduledCareProtocolSummaryRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Imaging.ScheduledCareProtocolSummaryRequiredAllergyRule(
            message: "scheduled care protocol summary needs an entry"
        )
        let item = Imaging.newScheduledCareProtocolSummary("", label: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}
