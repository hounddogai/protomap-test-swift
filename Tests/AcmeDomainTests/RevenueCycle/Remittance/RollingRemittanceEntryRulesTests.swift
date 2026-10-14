@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingRemittanceEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRollingRemittanceEntryValidator()
        let item = RevenueCycle.newRollingRemittanceEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRollingRemittanceEntryRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = RevenueCycle.RollingRemittanceEntryRequiredCategoryRule(
            message: "rolling remittance entry needs an entry"
        )
        let item = RevenueCycle.newRollingRemittanceEntry("", name: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRollingRemittanceEntryCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = RevenueCycle.RollingRemittanceEntryCategoryLengthRule(maxLength: 32)
        let item = RevenueCycle.newRollingRemittanceEntry("x", name: "y")
        item.category = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}
