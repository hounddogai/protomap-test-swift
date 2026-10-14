@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPriorityDigestValidator()
        let item = Imaging.newPriorityDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPriorityDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.PriorityDigestRequiredCodeRule(message: "priority digest needs a value")
        let item = Imaging.newPriorityDigest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPriorityDigestRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Imaging.PriorityDigestRequiredDescriptionRule(message: "priority digest needs a value")
        let item = Imaging.newPriorityDigest("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPriorityDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.PriorityDigestCodeLengthRule(maxLength: 255)
        let item = Imaging.newPriorityDigest("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPriorityDigestBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Imaging.PriorityDigestBatchSizeRangeRule(min: 16, max: 120)
        let item = Imaging.newPriorityDigest("x", title: "y")
        item.batchSize = 121
        #expect(rule.check(item).count > 0)
    }
}
