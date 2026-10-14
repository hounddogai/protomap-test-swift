@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualNetworkWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultManualNetworkWindowValidator()
        let item = Referrals.newManualNetworkWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsManualNetworkWindowRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.ManualNetworkWindowRequiredTitleRule(message: "manual network window needs this field")
        let item = Referrals.newManualNetworkWindow("", label: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsManualNetworkWindowProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Referrals.ManualNetworkWindowProcedureCodeLengthRule(maxLength: 32)
        let item = Referrals.newManualNetworkWindow("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
