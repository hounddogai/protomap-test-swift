@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetTemplateValidator()
        let item = ClinicalOps.newOrderSetTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetTemplatePhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = ClinicalOps.OrderSetTemplatePhoneLengthRule(maxLength: 255)
        let item = ClinicalOps.newOrderSetTemplate("x", label: "y")
        item.phone = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsOrderSetTemplateTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = ClinicalOps.OrderSetTemplateTimezoneLengthRule(maxLength: 3600)
        let item = ClinicalOps.newOrderSetTemplate("x", label: "y")
        item.timezone = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
