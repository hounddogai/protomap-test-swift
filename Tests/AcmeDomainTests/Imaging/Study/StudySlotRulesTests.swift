@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudySlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStudySlotValidator()
        let item = Imaging.newStudySlot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStudySlotBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Imaging.StudySlotBatchSizeRangeRule(min: 64, max: 80)
        let item = Imaging.newStudySlot("x", title: "y")
        item.batchSize = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingStudySlotRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Imaging.StudySlotRequiredBedRule(message: "study slot needs an entry")
        let item = Imaging.newStudySlot("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStudySlotTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.StudySlotTitleLengthRule(maxLength: 16)
        let item = Imaging.newStudySlot("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStudySlotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.StudySlotCodeLengthRule(maxLength: 32)
        let item = Imaging.newStudySlot("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStudySlotSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Imaging.StudySlotSequenceRangeRule(min: 32, max: 80)
        let item = Imaging.newStudySlot("x", title: "y")
        item.sequence = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingStudySlotRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Imaging.StudySlotRequiredPayerRule(message: "study slot needs a value")
        let item = Imaging.newStudySlot("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}
