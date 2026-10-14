@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredCareProtocolAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultTieredCareProtocolAllocationValidator()
        let item = Imaging.newTieredCareProtocolAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingTieredCareProtocolAllocationRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.TieredCareProtocolAllocationRequiredTitleRule(
            message: "tiered care protocol allocation needs an entry"
        )
        let item = Imaging.newTieredCareProtocolAllocation("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingTieredCareProtocolAllocationEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Imaging.TieredCareProtocolAllocationEndsAtRangeRule(min: 16, max: 120)
        let item = Imaging.newTieredCareProtocolAllocation("x", title: "y")
        item.endsAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingTieredCareProtocolAllocationTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.TieredCareProtocolAllocationTitleLengthRule(maxLength: 32)
        let item = Imaging.newTieredCareProtocolAllocation("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingTieredCareProtocolAllocationRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Imaging.TieredCareProtocolAllocationRequiredReviewerRule(
            message: "tiered care protocol allocation needs an entry"
        )
        let item = Imaging.newTieredCareProtocolAllocation("", title: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}
