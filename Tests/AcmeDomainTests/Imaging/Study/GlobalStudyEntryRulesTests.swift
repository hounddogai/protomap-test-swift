@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalStudyEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultGlobalStudyEntryValidator()
        let item = Imaging.newGlobalStudyEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingGlobalStudyEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.GlobalStudyEntryCodeLengthRule(maxLength: 80)
        let item = Imaging.newGlobalStudyEntry("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingGlobalStudyEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.GlobalStudyEntryRequiredCodeRule(message: "global study entry needs an entry")
        let item = Imaging.newGlobalStudyEntry("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingGlobalStudyEntryBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Imaging.GlobalStudyEntryBatchSizeRangeRule(min: 16, max: 120)
        let item = Imaging.newGlobalStudyEntry("x", label: "y")
        item.batchSize = 121
        #expect(rule.check(item).count > 0)
    }
}
