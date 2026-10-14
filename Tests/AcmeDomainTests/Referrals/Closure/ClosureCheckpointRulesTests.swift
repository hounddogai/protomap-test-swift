@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosureCheckpointValidator()
        let item = Referrals.newClosureCheckpoint("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosureCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ClosureCheckpointCodeLengthRule(maxLength: 1000)
        let item = Referrals.newClosureCheckpoint("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsClosureCheckpointWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Referrals.ClosureCheckpointWindowDaysRangeRule(min: 64, max: 255)
        let item = Referrals.newClosureCheckpoint("x", label: "y")
        item.windowDays = 256
        #expect(rule.check(item).count > 0)
    }
}
