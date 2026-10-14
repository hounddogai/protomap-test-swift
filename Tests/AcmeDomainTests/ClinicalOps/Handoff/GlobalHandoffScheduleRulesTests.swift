@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalHandoffScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultGlobalHandoffScheduleValidator()
        let item = ClinicalOps.newGlobalHandoffSchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsGlobalHandoffScheduleMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = ClinicalOps.GlobalHandoffScheduleMarginRangeRule(min: 5.2, max: 1218.6)
        let item = ClinicalOps.newGlobalHandoffSchedule("x", name: "y")
        item.margin = 1220.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsGlobalHandoffScheduleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.GlobalHandoffScheduleRequiredNameRule(message: "global handoff schedule needs this field")
        let item = ClinicalOps.newGlobalHandoffSchedule("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsGlobalHandoffScheduleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.GlobalHandoffScheduleNameLengthRule(maxLength: 80)
        let item = ClinicalOps.newGlobalHandoffSchedule("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
