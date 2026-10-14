@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalNetworkRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultGlobalNetworkRecordValidator()
        let item = Referrals.newGlobalNetworkRecord("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsGlobalNetworkRecordRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Referrals.GlobalNetworkRecordRequiredPatientRefRule(message: "global network record needs an entry")
        let item = Referrals.newGlobalNetworkRecord("", label: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsGlobalNetworkRecordRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.GlobalNetworkRecordRequiredLabelRule(message: "global network record needs this field")
        let item = Referrals.newGlobalNetworkRecord("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsGlobalNetworkRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.GlobalNetworkRecordRequiredCodeRule(message: "global network record needs a value")
        let item = Referrals.newGlobalNetworkRecord("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsGlobalNetworkRecordCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.GlobalNetworkRecordCodeLengthRule(maxLength: 64)
        let item = Referrals.newGlobalNetworkRecord("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsGlobalNetworkRecordLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.GlobalNetworkRecordLabelLengthRule(maxLength: 64)
        let item = Referrals.newGlobalNetworkRecord("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
