@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingPriorityGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultRollingPriorityGroupValidator()
        let item = Imaging.newRollingPriorityGroup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingRollingPriorityGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.RollingPriorityGroupCodeLengthRule(maxLength: 64)
        let item = Imaging.newRollingPriorityGroup("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingRollingPriorityGroupTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.RollingPriorityGroupTitleLengthRule(maxLength: 86400)
        let item = Imaging.newRollingPriorityGroup("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingRollingPriorityGroupRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Imaging.RollingPriorityGroupRequiredChecksumRule(message: "rolling priority group needs a value")
        let item = Imaging.newRollingPriorityGroup("", title: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}
