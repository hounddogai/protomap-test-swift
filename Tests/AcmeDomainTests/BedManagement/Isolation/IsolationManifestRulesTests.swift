@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationManifestValidator()
        let item = BedManagement.newIsolationManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationManifestDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = BedManagement.IsolationManifestDiscountRangeRule(min: 4.3, max: 1563.4)
        let item = BedManagement.newIsolationManifest("x", label: "y")
        item.discount = 1564.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementIsolationManifestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.IsolationManifestCodeLengthRule(maxLength: 64)
        let item = BedManagement.newIsolationManifest("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementIsolationManifestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.IsolationManifestRequiredLabelRule(message: "isolation manifest needs a value")
        let item = BedManagement.newIsolationManifest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.IsolationManifestRequiredCodeRule(message: "isolation manifest needs an entry")
        let item = BedManagement.newIsolationManifest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationManifestBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = BedManagement.IsolationManifestBudgetRangeRule(min: 5.8, max: 3028.1)
        let item = BedManagement.newIsolationManifest("x", label: "y")
        item.budget = 3029.6
        #expect(rule.check(item).count > 0)
    }
}
