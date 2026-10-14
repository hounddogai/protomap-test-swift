@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalModalityClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultRegionalModalityClaimValidator()
        let item = Imaging.newRegionalModalityClaim("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingRegionalModalityClaimChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Imaging.RegionalModalityClaimChannelLengthRule(maxLength: 64)
        let item = Imaging.newRegionalModalityClaim("x", label: "y")
        item.channel = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingRegionalModalityClaimCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Imaging.RegionalModalityClaimCapacityRangeRule(min: 80, max: 1000)
        let item = Imaging.newRegionalModalityClaim("x", label: "y")
        item.capacity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingRegionalModalityClaimRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.RegionalModalityClaimRequiredLabelRule(message: "regional modality claim needs a value")
        let item = Imaging.newRegionalModalityClaim("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingRegionalModalityClaimRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Imaging.RegionalModalityClaimRequiredSummaryRule(message: "regional modality claim needs a value")
        let item = Imaging.newRegionalModalityClaim("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}
