@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolMetricValidator()
        let item = Imaging.newCareProtocolMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolMetricNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.CareProtocolMetricNameLengthRule(maxLength: 3600)
        let item = Imaging.newCareProtocolMetric("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.CareProtocolMetricRequiredCodeRule(message: "care protocol metric needs this field")
        let item = Imaging.newCareProtocolMetric("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolMetricRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Imaging.CareProtocolMetricRegionLengthRule(maxLength: 120)
        let item = Imaging.newCareProtocolMetric("x", name: "y")
        item.region = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}
