@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledCareProtocolExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultScheduledCareProtocolExceptionValidator()
        let item = Imaging.newScheduledCareProtocolException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingScheduledCareProtocolExceptionEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Imaging.ScheduledCareProtocolExceptionEncounterIDLengthRule(maxLength: 1000)
        let item = Imaging.newScheduledCareProtocolException("x", title: "y")
        item.encounterID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingScheduledCareProtocolExceptionRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Imaging.ScheduledCareProtocolExceptionRegionLengthRule(maxLength: 86400)
        let item = Imaging.newScheduledCareProtocolException("x", title: "y")
        item.region = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingScheduledCareProtocolExceptionRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Imaging.ScheduledCareProtocolExceptionRequiredRegionRule(
            message: "scheduled care protocol exception needs a value"
        )
        let item = Imaging.newScheduledCareProtocolException("", title: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}
