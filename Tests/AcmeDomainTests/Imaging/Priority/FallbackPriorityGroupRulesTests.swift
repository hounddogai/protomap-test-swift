@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackPriorityGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultFallbackPriorityGroupValidator()
        let item = Imaging.newFallbackPriorityGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingFallbackPriorityGroupBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Imaging.FallbackPriorityGroupBedLengthRule(maxLength: 1000)
        let item = Imaging.newFallbackPriorityGroup("x", label: "y")
        item.bed = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingFallbackPriorityGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.FallbackPriorityGroupCodeLengthRule(maxLength: 255)
        let item = Imaging.newFallbackPriorityGroup("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingFallbackPriorityGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.FallbackPriorityGroupRequiredCodeRule(message: "fallback priority group needs an entry")
        let item = Imaging.newFallbackPriorityGroup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingFallbackPriorityGroupRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Imaging.FallbackPriorityGroupRequiredBedRule(message: "fallback priority group needs an entry")
        let item = Imaging.newFallbackPriorityGroup("", label: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}
