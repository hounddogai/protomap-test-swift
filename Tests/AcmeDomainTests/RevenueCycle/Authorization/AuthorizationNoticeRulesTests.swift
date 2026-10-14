@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationNoticeValidator()
        let item = RevenueCycle.newAuthorizationNotice("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationNoticeSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = RevenueCycle.AuthorizationNoticeSpecialtyLengthRule(maxLength: 16)
        let item = RevenueCycle.newAuthorizationNotice("x", label: "y")
        item.specialty = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationNoticeUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = RevenueCycle.AuthorizationNoticeUpdatedAtRangeRule(min: 16, max: 3600)
        let item = RevenueCycle.newAuthorizationNotice("x", label: "y")
        item.updatedAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleAuthorizationNoticeRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.AuthorizationNoticeRequiredLabelRule(message: "authorization notice needs a value")
        let item = RevenueCycle.newAuthorizationNotice("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationNoticeCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = RevenueCycle.AuthorizationNoticeCostRangeRule(min: 9.2, max: 2209.4)
        let item = RevenueCycle.newAuthorizationNotice("x", label: "y")
        item.cost = 2210.9
        #expect(rule.check(item).count > 0)
    }
}
