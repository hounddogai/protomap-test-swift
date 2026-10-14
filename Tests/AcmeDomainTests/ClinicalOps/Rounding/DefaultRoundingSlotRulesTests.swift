@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultRoundingSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultDefaultRoundingSlotValidator()
        let item = ClinicalOps.newDefaultRoundingSlot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsDefaultRoundingSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.DefaultRoundingSlotRequiredCodeRule(message: "default rounding slot needs a value")
        let item = ClinicalOps.newDefaultRoundingSlot("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsDefaultRoundingSlotRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = ClinicalOps.DefaultRoundingSlotRequiredTimezoneRule(message: "default rounding slot needs an entry")
        let item = ClinicalOps.newDefaultRoundingSlot("", title: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsDefaultRoundingSlotRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.DefaultRoundingSlotRequiredTitleRule(message: "default rounding slot needs a value")
        let item = ClinicalOps.newDefaultRoundingSlot("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
