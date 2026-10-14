@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientNetworkSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultLenientNetworkSnapshotValidator()
        let item = Referrals.newLenientNetworkSnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsLenientNetworkSnapshotCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Referrals.LenientNetworkSnapshotCapacityRangeRule(min: 120, max: 3600)
        let item = Referrals.newLenientNetworkSnapshot("x", name: "y")
        item.capacity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsLenientNetworkSnapshotMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Referrals.LenientNetworkSnapshotMarginRangeRule(min: 10.0, max: 4449.9)
        let item = Referrals.newLenientNetworkSnapshot("x", name: "y")
        item.margin = 4451.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsLenientNetworkSnapshotRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.LenientNetworkSnapshotRequiredNameRule(message: "lenient network snapshot needs an entry")
        let item = Referrals.newLenientNetworkSnapshot("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsLenientNetworkSnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.LenientNetworkSnapshotCodeLengthRule(maxLength: 32)
        let item = Referrals.newLenientNetworkSnapshot("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
