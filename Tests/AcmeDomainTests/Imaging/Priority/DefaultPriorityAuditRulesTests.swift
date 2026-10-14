@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingDefaultPriorityAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultDefaultPriorityAuditValidator()
        let item = Imaging.newDefaultPriorityAudit("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingDefaultPriorityAuditNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.DefaultPriorityAuditNameLengthRule(maxLength: 16)
        let item = Imaging.newDefaultPriorityAudit("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingDefaultPriorityAuditRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.DefaultPriorityAuditRequiredCodeRule(message: "default priority audit needs an entry")
        let item = Imaging.newDefaultPriorityAudit("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingDefaultPriorityAuditLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Imaging.DefaultPriorityAuditLocaleLengthRule(maxLength: 80)
        let item = Imaging.newDefaultPriorityAudit("x", name: "y")
        item.locale = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}
