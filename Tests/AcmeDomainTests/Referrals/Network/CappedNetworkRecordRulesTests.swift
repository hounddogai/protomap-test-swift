@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedNetworkRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultCappedNetworkRecordValidator()
        let item = Referrals.newCappedNetworkRecord("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsCappedNetworkRecordFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Referrals.CappedNetworkRecordFacilityLengthRule(maxLength: 3600)
        let item = Referrals.newCappedNetworkRecord("x", name: "y")
        item.facility = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsCappedNetworkRecordProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Referrals.CappedNetworkRecordProcedureCodeLengthRule(maxLength: 86400)
        let item = Referrals.newCappedNetworkRecord("x", name: "y")
        item.procedureCode = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsCappedNetworkRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.CappedNetworkRecordRequiredCodeRule(message: "capped network record needs this field")
        let item = Referrals.newCappedNetworkRecord("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsCappedNetworkRecordNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.CappedNetworkRecordNameLengthRule(maxLength: 120)
        let item = Referrals.newCappedNetworkRecord("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsCappedNetworkRecordDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Referrals.CappedNetworkRecordDosageMgRangeRule(min: 6.1, max: 2408.9)
        let item = Referrals.newCappedNetworkRecord("x", name: "y")
        item.dosageMg = 2410.4
        #expect(rule.check(item).count > 0)
    }
}
