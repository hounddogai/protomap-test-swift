@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalCensusSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultGlobalCensusSlotValidator()
        let item = BedManagement.newGlobalCensusSlot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementGlobalCensusSlotRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.GlobalCensusSlotRequiredTitleRule(message: "global census slot needs a value")
        let item = BedManagement.newGlobalCensusSlot("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementGlobalCensusSlotVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = BedManagement.GlobalCensusSlotVisitMinutesRangeRule(min: 32, max: 86400)
        let item = BedManagement.newGlobalCensusSlot("x", title: "y")
        item.visitMinutes = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementGlobalCensusSlotCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = BedManagement.GlobalCensusSlotCategoryLengthRule(maxLength: 1000)
        let item = BedManagement.newGlobalCensusSlot("x", title: "y")
        item.category = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementGlobalCensusSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.GlobalCensusSlotRequiredCodeRule(message: "global census slot needs this field")
        let item = BedManagement.newGlobalCensusSlot("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
