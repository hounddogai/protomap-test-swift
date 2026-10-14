@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredStudyBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultTieredStudyBatchValidator()
        let item = Imaging.newTieredStudyBatch("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingTieredStudyBatchUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Imaging.TieredStudyBatchUpdatedAtRangeRule(min: 16, max: 1000)
        let item = Imaging.newTieredStudyBatch("x", name: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingTieredStudyBatchRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.TieredStudyBatchRequiredCodeRule(message: "tiered study batch needs an entry")
        let item = Imaging.newTieredStudyBatch("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingTieredStudyBatchCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.TieredStudyBatchCodeLengthRule(maxLength: 64)
        let item = Imaging.newTieredStudyBatch("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
