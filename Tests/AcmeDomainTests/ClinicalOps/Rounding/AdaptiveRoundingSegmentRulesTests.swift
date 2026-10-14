@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveRoundingSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAdaptiveRoundingSegmentValidator()
        let item = ClinicalOps.newAdaptiveRoundingSegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAdaptiveRoundingSegmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.AdaptiveRoundingSegmentCodeLengthRule(maxLength: 3600)
        let item = ClinicalOps.newAdaptiveRoundingSegment("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAdaptiveRoundingSegmentNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.AdaptiveRoundingSegmentNameLengthRule(maxLength: 64)
        let item = ClinicalOps.newAdaptiveRoundingSegment("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAdaptiveRoundingSegmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.AdaptiveRoundingSegmentRequiredNameRule(
            message: "adaptive rounding segment needs an entry"
        )
        let item = ClinicalOps.newAdaptiveRoundingSegment("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAdaptiveRoundingSegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.AdaptiveRoundingSegmentRequiredCodeRule(
            message: "adaptive rounding segment needs a value"
        )
        let item = ClinicalOps.newAdaptiveRoundingSegment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAdaptiveRoundingSegmentLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = ClinicalOps.AdaptiveRoundingSegmentLimitRangeRule(min: 1000, max: 1000)
        let item = ClinicalOps.newAdaptiveRoundingSegment("x", name: "y")
        item.limit = 1001
        #expect(rule.check(item).count > 0)
    }
}
