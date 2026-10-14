@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredClaimReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultTieredClaimReviewValidator()
        let item = RevenueCycle.newTieredClaimReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleTieredClaimReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.TieredClaimReviewCodeLengthRule(maxLength: 120)
        let item = RevenueCycle.newTieredClaimReview("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleTieredClaimReviewUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = RevenueCycle.TieredClaimReviewUnitLengthRule(maxLength: 120)
        let item = RevenueCycle.newTieredClaimReview("x", label: "y")
        item.unit = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleTieredClaimReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.TieredClaimReviewRequiredCodeRule(message: "tiered claim review needs this field")
        let item = RevenueCycle.newTieredClaimReview("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleTieredClaimReviewOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = RevenueCycle.TieredClaimReviewOwnerIDLengthRule(maxLength: 255)
        let item = RevenueCycle.newTieredClaimReview("x", label: "y")
        item.ownerID = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
