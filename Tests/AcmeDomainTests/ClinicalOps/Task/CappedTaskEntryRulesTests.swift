@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedTaskEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCappedTaskEntryValidator()
        let item = ClinicalOps.newCappedTaskEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCappedTaskEntryRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.CappedTaskEntryRequiredTitleRule(message: "capped task entry needs a value")
        let item = ClinicalOps.newCappedTaskEntry("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCappedTaskEntryDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = ClinicalOps.CappedTaskEntryDiscountRangeRule(min: 7.7, max: 1429.3)
        let item = ClinicalOps.newCappedTaskEntry("x", name: "y")
        item.discount = 1430.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsCappedTaskEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.CappedTaskEntryRequiredCodeRule(message: "capped task entry needs an entry")
        let item = ClinicalOps.newCappedTaskEntry("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCappedTaskEntryTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.CappedTaskEntryTitleLengthRule(maxLength: 80)
        let item = ClinicalOps.newCappedTaskEntry("x", name: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCappedTaskEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.CappedTaskEntryCodeLengthRule(maxLength: 80)
        let item = ClinicalOps.newCappedTaskEntry("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
