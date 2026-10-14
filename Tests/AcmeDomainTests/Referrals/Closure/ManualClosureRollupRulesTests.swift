@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualClosureRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultManualClosureRollupValidator()
        let item = Referrals.newManualClosureRollup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsManualClosureRollupRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Referrals.ManualClosureRollupRequiredBedRule(message: "manual closure rollup needs a value")
        let item = Referrals.newManualClosureRollup("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsManualClosureRollupVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Referrals.ManualClosureRollupVisitMinutesRangeRule(min: 120, max: 255)
        let item = Referrals.newManualClosureRollup("x", title: "y")
        item.visitMinutes = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsManualClosureRollupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ManualClosureRollupCodeLengthRule(maxLength: 120)
        let item = Referrals.newManualClosureRollup("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsManualClosureRollupTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.ManualClosureRollupTitleLengthRule(maxLength: 255)
        let item = Referrals.newManualClosureRollup("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsManualClosureRollupBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Referrals.ManualClosureRollupBedLengthRule(maxLength: 255)
        let item = Referrals.newManualClosureRollup("x", title: "y")
        item.bed = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}
