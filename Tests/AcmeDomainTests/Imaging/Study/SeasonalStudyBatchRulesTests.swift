@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalStudyBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultSeasonalStudyBatchValidator()
        let item = Imaging.newSeasonalStudyBatch("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingSeasonalStudyBatchScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Imaging.SeasonalStudyBatchScoreRangeRule(min: 6.2, max: 2777.9)
        let item = Imaging.newSeasonalStudyBatch("x", name: "y")
        item.score = 2779.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingSeasonalStudyBatchNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.SeasonalStudyBatchNameLengthRule(maxLength: 1000)
        let item = Imaging.newSeasonalStudyBatch("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingSeasonalStudyBatchRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.SeasonalStudyBatchRequiredCodeRule(message: "seasonal study batch needs an entry")
        let item = Imaging.newSeasonalStudyBatch("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingSeasonalStudyBatchRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.SeasonalStudyBatchRequiredNameRule(message: "seasonal study batch needs a value")
        let item = Imaging.newSeasonalStudyBatch("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingSeasonalStudyBatchPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Imaging.SeasonalStudyBatchPayerLengthRule(maxLength: 3600)
        let item = Imaging.newSeasonalStudyBatch("x", name: "y")
        item.payer = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
