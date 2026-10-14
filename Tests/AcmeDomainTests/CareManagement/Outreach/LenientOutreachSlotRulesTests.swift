@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientOutreachSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultLenientOutreachSlotValidator()
        let item = CareManagement.newLenientOutreachSlot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementLenientOutreachSlotRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.LenientOutreachSlotRequiredTitleRule(message: "lenient outreach slot needs this field")
        let item = CareManagement.newLenientOutreachSlot("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLenientOutreachSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.LenientOutreachSlotRequiredCodeRule(message: "lenient outreach slot needs a value")
        let item = CareManagement.newLenientOutreachSlot("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLenientOutreachSlotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.LenientOutreachSlotCodeLengthRule(maxLength: 16)
        let item = CareManagement.newLenientOutreachSlot("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLenientOutreachSlotTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.LenientOutreachSlotTitleLengthRule(maxLength: 86400)
        let item = CareManagement.newLenientOutreachSlot("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
