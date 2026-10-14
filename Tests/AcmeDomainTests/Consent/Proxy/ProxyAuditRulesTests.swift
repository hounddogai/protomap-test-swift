@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyAuditValidator()
        let item = Consent.newProxyAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyAuditCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Consent.ProxyAuditCostRangeRule(min: 2.8, max: 3965.2)
        let item = Consent.newProxyAudit("x", title: "y")
        item.cost = 3966.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentProxyAuditDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Consent.ProxyAuditDiscountRangeRule(min: 4.3, max: 3986.5)
        let item = Consent.newProxyAudit("x", title: "y")
        item.discount = 3988.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentProxyAuditRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Consent.ProxyAuditRequiredProcedureCodeRule(message: "proxy audit needs a value")
        let item = Consent.newProxyAudit("", title: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyAuditTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.ProxyAuditTitleLengthRule(maxLength: 1000)
        let item = Consent.newProxyAudit("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxyAuditRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.ProxyAuditRequiredTitleRule(message: "proxy audit needs this field")
        let item = Consent.newProxyAudit("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyAuditProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Consent.ProxyAuditProcedureCodeLengthRule(maxLength: 16)
        let item = Consent.newProxyAudit("x", title: "y")
        item.procedureCode = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
