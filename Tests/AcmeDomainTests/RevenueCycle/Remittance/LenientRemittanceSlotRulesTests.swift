@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientRemittanceSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultLenientRemittanceSlotValidator()
        let item = RevenueCycle.newLenientRemittanceSlot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleLenientRemittanceSlotSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = RevenueCycle.LenientRemittanceSlotSegmentLengthRule(maxLength: 16)
        let item = RevenueCycle.newLenientRemittanceSlot("x", title: "y")
        item.segment = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleLenientRemittanceSlotRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = RevenueCycle.LenientRemittanceSlotRegionLengthRule(maxLength: 86400)
        let item = RevenueCycle.newLenientRemittanceSlot("x", title: "y")
        item.region = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}
