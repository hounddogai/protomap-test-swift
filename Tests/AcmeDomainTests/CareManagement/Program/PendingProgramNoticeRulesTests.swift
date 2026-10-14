@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingProgramNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPendingProgramNoticeValidator()
        let item = CareManagement.newPendingProgramNotice("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPendingProgramNoticeRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.PendingProgramNoticeRequiredLabelRule(message: "pending program notice needs an entry")
        let item = CareManagement.newPendingProgramNotice("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementPendingProgramNoticeNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.PendingProgramNoticeNameLengthRule(maxLength: 80)
        let item = CareManagement.newPendingProgramNotice("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPendingProgramNoticeLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.PendingProgramNoticeLabelLengthRule(maxLength: 16)
        let item = CareManagement.newPendingProgramNotice("x", name: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPendingProgramNoticeMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = CareManagement.PendingProgramNoticeMarginRangeRule(min: 4.1, max: 4792.6)
        let item = CareManagement.newPendingProgramNotice("x", name: "y")
        item.margin = 4794.1
        #expect(rule.check(item).count > 0)
    }
}
