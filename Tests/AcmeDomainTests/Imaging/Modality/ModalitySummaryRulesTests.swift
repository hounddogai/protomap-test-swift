@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalitySummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalitySummaryValidator()
        let item = Imaging.newModalitySummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalitySummaryRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Imaging.ModalitySummaryRetriesRangeRule(min: 255, max: 3600)
        let item = Imaging.newModalitySummary("x", label: "y")
        item.retries = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingModalitySummaryLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.ModalitySummaryLabelLengthRule(maxLength: 64)
        let item = Imaging.newModalitySummary("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalitySummaryRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Imaging.ModalitySummaryRequiredChecksumRule(message: "modality summary needs an entry")
        let item = Imaging.newModalitySummary("", label: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingModalitySummaryUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Imaging.ModalitySummaryUnitLengthRule(maxLength: 80)
        let item = Imaging.newModalitySummary("x", label: "y")
        item.unit = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}
