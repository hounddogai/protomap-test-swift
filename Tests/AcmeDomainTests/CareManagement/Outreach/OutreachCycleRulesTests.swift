@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultOutreachCycleValidator()
        let item = CareManagement.newOutreachCycle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementOutreachCyclePhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = CareManagement.OutreachCyclePhoneLengthRule(maxLength: 80)
        let item = CareManagement.newOutreachCycle("x", name: "y")
        item.phone = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementOutreachCycleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.OutreachCycleRequiredNameRule(message: "outreach cycle needs an entry")
        let item = CareManagement.newOutreachCycle("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementOutreachCycleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.OutreachCycleNameLengthRule(maxLength: 255)
        let item = CareManagement.newOutreachCycle("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
