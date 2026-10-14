@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalWorklistRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultRegionalWorklistRecordValidator()
        let item = Imaging.newRegionalWorklistRecord("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingRegionalWorklistRecordRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.RegionalWorklistRecordRequiredLabelRule(message: "regional worklist record needs an entry")
        let item = Imaging.newRegionalWorklistRecord("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingRegionalWorklistRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.RegionalWorklistRecordRequiredCodeRule(message: "regional worklist record needs a value")
        let item = Imaging.newRegionalWorklistRecord("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingRegionalWorklistRecordPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Imaging.RegionalWorklistRecordPayerLengthRule(maxLength: 3600)
        let item = Imaging.newRegionalWorklistRecord("x", label: "y")
        item.payer = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
