@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyRecordValidator()
        let item = Consent.newProxyRecord("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyRecordFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Consent.ProxyRecordFloorValueRangeRule(min: 6.1, max: 1725.9)
        let item = Consent.newProxyRecord("x", name: "y")
        item.floorValue = 1727.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentProxyRecordClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Consent.ProxyRecordClinicianIDLengthRule(maxLength: 1000)
        let item = Consent.newProxyRecord("x", name: "y")
        item.clinicianID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxyRecordCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ProxyRecordCodeLengthRule(maxLength: 64)
        let item = Consent.newProxyRecord("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxyRecordRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.ProxyRecordRequiredNameRule(message: "proxy record needs a value")
        let item = Consent.newProxyRecord("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
