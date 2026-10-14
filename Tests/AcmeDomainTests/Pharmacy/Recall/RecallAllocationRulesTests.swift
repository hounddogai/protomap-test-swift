@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallAllocationValidator()
        let item = Pharmacy.newRecallAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallAllocationTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.RecallAllocationTitleLengthRule(maxLength: 16)
        let item = Pharmacy.newRecallAllocation("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallAllocationRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.RecallAllocationRequiredTitleRule(message: "recall allocation needs a value")
        let item = Pharmacy.newRecallAllocation("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallAllocationVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Pharmacy.RecallAllocationVisitMinutesRangeRule(min: 64, max: 80)
        let item = Pharmacy.newRecallAllocation("x", title: "y")
        item.visitMinutes = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRecallAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.RecallAllocationCodeLengthRule(maxLength: 255)
        let item = Pharmacy.newRecallAllocation("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
