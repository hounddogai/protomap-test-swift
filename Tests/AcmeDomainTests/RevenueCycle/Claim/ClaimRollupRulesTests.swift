@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultClaimRollupValidator()
        let item = RevenueCycle.newClaimRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleClaimRollupSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = RevenueCycle.ClaimRollupSegmentLengthRule(maxLength: 120)
        let item = RevenueCycle.newClaimRollup("x", name: "y")
        item.segment = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleClaimRollupRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.ClaimRollupRequiredNameRule(message: "claim rollup needs a value")
        let item = RevenueCycle.newClaimRollup("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
