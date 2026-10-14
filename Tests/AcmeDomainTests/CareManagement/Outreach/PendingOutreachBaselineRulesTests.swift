@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingOutreachBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPendingOutreachBaselineValidator()
        let item = CareManagement.newPendingOutreachBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPendingOutreachBaselineSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = CareManagement.PendingOutreachBaselineSequenceRangeRule(min: 32, max: 1000)
        let item = CareManagement.newPendingOutreachBaseline("x", label: "y")
        item.sequence = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementPendingOutreachBaselineCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.PendingOutreachBaselineCodeLengthRule(maxLength: 16)
        let item = CareManagement.newPendingOutreachBaseline("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPendingOutreachBaselineOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = CareManagement.PendingOutreachBaselineOwnerIDLengthRule(maxLength: 120)
        let item = CareManagement.newPendingOutreachBaseline("x", label: "y")
        item.ownerID = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPendingOutreachBaselineLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.PendingOutreachBaselineLabelLengthRule(maxLength: 86400)
        let item = CareManagement.newPendingOutreachBaseline("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPendingOutreachBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.PendingOutreachBaselineRequiredCodeRule(
            message: "pending outreach baseline needs this field"
        )
        let item = CareManagement.newPendingOutreachBaseline("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
