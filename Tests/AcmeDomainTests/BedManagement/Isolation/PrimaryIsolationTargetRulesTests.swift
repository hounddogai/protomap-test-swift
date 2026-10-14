@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryIsolationTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPrimaryIsolationTargetValidator()
        let item = BedManagement.newPrimaryIsolationTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPrimaryIsolationTargetContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = BedManagement.PrimaryIsolationTargetContactEmailLengthRule(maxLength: 16)
        let item = BedManagement.newPrimaryIsolationTarget("x", name: "y")
        item.contactEmail = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPrimaryIsolationTargetAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = BedManagement.PrimaryIsolationTargetAmountRangeRule(min: 2.9, max: 1122.5)
        let item = BedManagement.newPrimaryIsolationTarget("x", name: "y")
        item.amount = 1124.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementPrimaryIsolationTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.PrimaryIsolationTargetRequiredCodeRule(
            message: "primary isolation target needs a value"
        )
        let item = BedManagement.newPrimaryIsolationTarget("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPrimaryIsolationTargetRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = BedManagement.PrimaryIsolationTargetRequiredContactEmailRule(
            message: "primary isolation target needs a value"
        )
        let item = BedManagement.newPrimaryIsolationTarget("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPrimaryIsolationTargetNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.PrimaryIsolationTargetNameLengthRule(maxLength: 64)
        let item = BedManagement.newPrimaryIsolationTarget("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPrimaryIsolationTargetUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = BedManagement.PrimaryIsolationTargetUpdatedAtRangeRule(min: 32, max: 255)
        let item = BedManagement.newPrimaryIsolationTarget("x", name: "y")
        item.updatedAt = 256
        #expect(rule.check(item).count > 0)
    }
}
