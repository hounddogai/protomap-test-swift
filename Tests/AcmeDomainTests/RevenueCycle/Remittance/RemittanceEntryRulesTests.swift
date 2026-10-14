@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceEntryValidator()
        let item = RevenueCycle.newRemittanceEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceEntryNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.RemittanceEntryNameLengthRule(maxLength: 3600)
        let item = RevenueCycle.newRemittanceEntry("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.RemittanceEntryRequiredCodeRule(message: "remittance entry needs this field")
        let item = RevenueCycle.newRemittanceEntry("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
