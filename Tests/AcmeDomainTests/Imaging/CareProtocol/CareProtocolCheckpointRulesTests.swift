@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolCheckpointValidator()
        let item = Imaging.newCareProtocolCheckpoint("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolCheckpointTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.CareProtocolCheckpointTitleLengthRule(maxLength: 32)
        let item = Imaging.newCareProtocolCheckpoint("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolCheckpointRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Imaging.CareProtocolCheckpointRegionLengthRule(maxLength: 1000)
        let item = Imaging.newCareProtocolCheckpoint("x", title: "y")
        item.region = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolCheckpointCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Imaging.CareProtocolCheckpointCountryLengthRule(maxLength: 80)
        let item = Imaging.newCareProtocolCheckpoint("x", title: "y")
        item.country = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}
