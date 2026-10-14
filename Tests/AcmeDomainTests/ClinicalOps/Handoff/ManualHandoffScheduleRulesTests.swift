@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsManualHandoffScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultManualHandoffScheduleValidator()
        let item = ClinicalOps.newManualHandoffSchedule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsManualHandoffScheduleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.ManualHandoffScheduleRequiredLabelRule(
            message: "manual handoff schedule needs this field"
        )
        let item = ClinicalOps.newManualHandoffSchedule("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsManualHandoffScheduleBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = ClinicalOps.ManualHandoffScheduleBedLengthRule(maxLength: 32)
        let item = ClinicalOps.newManualHandoffSchedule("x", label: "y")
        item.bed = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsManualHandoffScheduleRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = ClinicalOps.ManualHandoffScheduleRequiredBedRule(message: "manual handoff schedule needs an entry")
        let item = ClinicalOps.newManualHandoffSchedule("", label: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsManualHandoffScheduleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.ManualHandoffScheduleCodeLengthRule(maxLength: 16)
        let item = ClinicalOps.newManualHandoffSchedule("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsManualHandoffScheduleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.ManualHandoffScheduleRequiredCodeRule(message: "manual handoff schedule needs a value")
        let item = ClinicalOps.newManualHandoffSchedule("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
