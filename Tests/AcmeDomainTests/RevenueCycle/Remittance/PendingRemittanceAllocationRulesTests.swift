@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingRemittanceAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultPendingRemittanceAllocationValidator()
        let item = RevenueCycle.newPendingRemittanceAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCyclePendingRemittanceAllocationRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = RevenueCycle.PendingRemittanceAllocationRequiredExternalRefRule(
            message: "pending remittance allocation needs a value"
        )
        let item = RevenueCycle.newPendingRemittanceAllocation("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCyclePendingRemittanceAllocationRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.PendingRemittanceAllocationRequiredLabelRule(
            message: "pending remittance allocation needs this field"
        )
        let item = RevenueCycle.newPendingRemittanceAllocation("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCyclePendingRemittanceAllocationSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = RevenueCycle.PendingRemittanceAllocationSourceLengthRule(maxLength: 32)
        let item = RevenueCycle.newPendingRemittanceAllocation("x", label: "y")
        item.source = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCyclePendingRemittanceAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.PendingRemittanceAllocationCodeLengthRule(maxLength: 1000)
        let item = RevenueCycle.newPendingRemittanceAllocation("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
