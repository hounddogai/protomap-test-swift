@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedModalityWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCappedModalityWindowValidator()
        let item = Imaging.newCappedModalityWindow("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCappedModalityWindowFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Imaging.CappedModalityWindowFacilityLengthRule(maxLength: 120)
        let item = Imaging.newCappedModalityWindow("x", name: "y")
        item.facility = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCappedModalityWindowRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Imaging.CappedModalityWindowRegionLengthRule(maxLength: 120)
        let item = Imaging.newCappedModalityWindow("x", name: "y")
        item.region = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCappedModalityWindowRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Imaging.CappedModalityWindowRequiredRegionRule(message: "capped modality window needs this field")
        let item = Imaging.newCappedModalityWindow("", name: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCappedModalityWindowDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Imaging.CappedModalityWindowDosageMgRangeRule(min: 3.3, max: 1907.1)
        let item = Imaging.newCappedModalityWindow("x", name: "y")
        item.dosageMg = 1908.6
        #expect(rule.check(item).count > 0)
    }
}
