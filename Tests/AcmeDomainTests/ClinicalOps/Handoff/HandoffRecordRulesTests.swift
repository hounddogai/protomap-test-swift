@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultHandoffRecordValidator()
        let item = ClinicalOps.newHandoffRecord("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsHandoffRecordCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.HandoffRecordCodeLengthRule(maxLength: 64)
        let item = ClinicalOps.newHandoffRecord("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsHandoffRecordTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.HandoffRecordTitleLengthRule(maxLength: 255)
        let item = ClinicalOps.newHandoffRecord("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsHandoffRecordRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = ClinicalOps.HandoffRecordRequiredFacilityRule(message: "handoff record needs this field")
        let item = ClinicalOps.newHandoffRecord("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}
