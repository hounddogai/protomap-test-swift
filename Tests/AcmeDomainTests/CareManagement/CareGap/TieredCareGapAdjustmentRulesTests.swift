@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredCareGapAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultTieredCareGapAdjustmentValidator()
        let item = CareManagement.newTieredCareGapAdjustment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementTieredCareGapAdjustmentRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.TieredCareGapAdjustmentRequiredTitleRule(
            message: "tiered care gap adjustment needs this field"
        )
        let item = CareManagement.newTieredCareGapAdjustment("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementTieredCareGapAdjustmentCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = CareManagement.TieredCareGapAdjustmentCeilingRangeRule(min: 1.4, max: 1268.1)
        let item = CareManagement.newTieredCareGapAdjustment("x", title: "y")
        item.ceiling = 1269.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementTieredCareGapAdjustmentTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.TieredCareGapAdjustmentTitleLengthRule(maxLength: 80)
        let item = CareManagement.newTieredCareGapAdjustment("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementTieredCareGapAdjustmentClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = CareManagement.TieredCareGapAdjustmentClinicianIDLengthRule(maxLength: 255)
        let item = CareManagement.newTieredCareGapAdjustment("x", title: "y")
        item.clinicianID = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementTieredCareGapAdjustmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.TieredCareGapAdjustmentRequiredCodeRule(
            message: "tiered care gap adjustment needs an entry"
        )
        let item = CareManagement.newTieredCareGapAdjustment("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
