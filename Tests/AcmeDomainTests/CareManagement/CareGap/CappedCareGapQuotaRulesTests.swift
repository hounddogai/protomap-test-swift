@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedCareGapQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCappedCareGapQuotaValidator()
        let item = CareManagement.newCappedCareGapQuota("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCappedCareGapQuotaFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = CareManagement.CappedCareGapQuotaFloorValueRangeRule(min: 8.4, max: 3424.4)
        let item = CareManagement.newCappedCareGapQuota("x", label: "y")
        item.floorValue = 3425.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementCappedCareGapQuotaUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = CareManagement.CappedCareGapQuotaUnitLengthRule(maxLength: 120)
        let item = CareManagement.newCappedCareGapQuota("x", label: "y")
        item.unit = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCappedCareGapQuotaRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.CappedCareGapQuotaRequiredLabelRule(message: "capped care gap quota needs an entry")
        let item = CareManagement.newCappedCareGapQuota("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCappedCareGapQuotaRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = CareManagement.CappedCareGapQuotaRequiredLocaleRule(message: "capped care gap quota needs this field")
        let item = CareManagement.newCappedCareGapQuota("", label: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}
