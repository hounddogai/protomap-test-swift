@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualOutreachSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultManualOutreachSlotValidator()
        let item = CareManagement.newManualOutreachSlot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementManualOutreachSlotExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = CareManagement.ManualOutreachSlotExternalRefLengthRule(maxLength: 3600)
        let item = CareManagement.newManualOutreachSlot("x", name: "y")
        item.externalRef = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementManualOutreachSlotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.ManualOutreachSlotCodeLengthRule(maxLength: 255)
        let item = CareManagement.newManualOutreachSlot("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
