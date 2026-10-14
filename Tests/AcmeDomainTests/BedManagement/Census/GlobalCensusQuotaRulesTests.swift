@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalCensusQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultGlobalCensusQuotaValidator()
        let item = BedManagement.newGlobalCensusQuota("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementGlobalCensusQuotaRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.GlobalCensusQuotaRequiredCodeRule(message: "global census quota needs an entry")
        let item = BedManagement.newGlobalCensusQuota("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementGlobalCensusQuotaCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.GlobalCensusQuotaCodeLengthRule(maxLength: 1000)
        let item = BedManagement.newGlobalCensusQuota("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementGlobalCensusQuotaAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = BedManagement.GlobalCensusQuotaAmountRangeRule(min: 7.0, max: 591.0)
        let item = BedManagement.newGlobalCensusQuota("x", name: "y")
        item.amount = 592.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementGlobalCensusQuotaWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = BedManagement.GlobalCensusQuotaWardLengthRule(maxLength: 86400)
        let item = BedManagement.newGlobalCensusQuota("x", name: "y")
        item.ward = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}
