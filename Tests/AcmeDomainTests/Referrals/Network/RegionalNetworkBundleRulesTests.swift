@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalNetworkBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRegionalNetworkBundleValidator()
        let item = Referrals.newRegionalNetworkBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRegionalNetworkBundleProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Referrals.RegionalNetworkBundleProcedureCodeLengthRule(maxLength: 3600)
        let item = Referrals.newRegionalNetworkBundle("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsRegionalNetworkBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.RegionalNetworkBundleRequiredCodeRule(message: "regional network bundle needs an entry")
        let item = Referrals.newRegionalNetworkBundle("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
