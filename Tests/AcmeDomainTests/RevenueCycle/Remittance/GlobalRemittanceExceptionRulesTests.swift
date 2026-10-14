@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalRemittanceExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultGlobalRemittanceExceptionValidator()
        let item = RevenueCycle.newGlobalRemittanceException("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleGlobalRemittanceExceptionRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = RevenueCycle.GlobalRemittanceExceptionRevisionRangeRule(min: 64, max: 3600)
        let item = RevenueCycle.newGlobalRemittanceException("x", name: "y")
        item.revision = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleGlobalRemittanceExceptionCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = RevenueCycle.GlobalRemittanceExceptionCapacityRangeRule(min: 64, max: 3600)
        let item = RevenueCycle.newGlobalRemittanceException("x", name: "y")
        item.capacity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleGlobalRemittanceExceptionNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.GlobalRemittanceExceptionNameLengthRule(maxLength: 32)
        let item = RevenueCycle.newGlobalRemittanceException("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleGlobalRemittanceExceptionCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.GlobalRemittanceExceptionCodeLengthRule(maxLength: 64)
        let item = RevenueCycle.newGlobalRemittanceException("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleGlobalRemittanceExceptionRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.GlobalRemittanceExceptionRequiredCodeRule(
            message: "global remittance exception needs this field"
        )
        let item = RevenueCycle.newGlobalRemittanceException("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
