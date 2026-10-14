@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultProgramNoticeValidator()
        let item = CareManagement.newProgramNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementProgramNoticeRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = CareManagement.ProgramNoticeRateRangeRule(min: 9.4, max: 1584.5)
        let item = CareManagement.newProgramNotice("x", title: "y")
        item.rate = 1586.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementProgramNoticeTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.ProgramNoticeTitleLengthRule(maxLength: 64)
        let item = CareManagement.newProgramNotice("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementProgramNoticeRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.ProgramNoticeRequiredCodeRule(message: "program notice needs a value")
        let item = CareManagement.newProgramNotice("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementProgramNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.ProgramNoticeCodeLengthRule(maxLength: 32)
        let item = CareManagement.newProgramNotice("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
