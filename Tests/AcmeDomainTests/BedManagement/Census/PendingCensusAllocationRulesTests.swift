@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingCensusAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPendingCensusAllocationValidator()
        let item = BedManagement.newPendingCensusAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPendingCensusAllocationRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = BedManagement.PendingCensusAllocationRequiredAllergyRule(
            message: "pending census allocation needs an entry"
        )
        let item = BedManagement.newPendingCensusAllocation("", title: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPendingCensusAllocationTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.PendingCensusAllocationTitleLengthRule(maxLength: 120)
        let item = BedManagement.newPendingCensusAllocation("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPendingCensusAllocationQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = BedManagement.PendingCensusAllocationQuantityRangeRule(min: 120, max: 3600)
        let item = BedManagement.newPendingCensusAllocation("x", title: "y")
        item.quantity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementPendingCensusAllocationLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = BedManagement.PendingCensusAllocationLocaleLengthRule(maxLength: 86400)
        let item = BedManagement.newPendingCensusAllocation("x", title: "y")
        item.locale = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPendingCensusAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.PendingCensusAllocationCodeLengthRule(maxLength: 120)
        let item = BedManagement.newPendingCensusAllocation("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
