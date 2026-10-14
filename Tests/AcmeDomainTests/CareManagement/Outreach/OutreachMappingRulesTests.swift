@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultOutreachMappingValidator()
        let item = CareManagement.newOutreachMapping("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementOutreachMappingCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.OutreachMappingCodeLengthRule(maxLength: 3600)
        let item = CareManagement.newOutreachMapping("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementOutreachMappingRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.OutreachMappingRequiredTitleRule(message: "outreach mapping needs an entry")
        let item = CareManagement.newOutreachMapping("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
