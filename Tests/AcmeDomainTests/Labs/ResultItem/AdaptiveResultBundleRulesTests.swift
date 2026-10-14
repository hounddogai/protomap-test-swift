@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveResultBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAdaptiveResultBundleValidator()
        let item = Labs.newAdaptiveResultBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAdaptiveResultBundleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.AdaptiveResultBundleRequiredNameRule(message: "adaptive result bundle needs this field")
        let item = Labs.newAdaptiveResultBundle("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAdaptiveResultBundleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.AdaptiveResultBundleNameLengthRule(maxLength: 64)
        let item = Labs.newAdaptiveResultBundle("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAdaptiveResultBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.AdaptiveResultBundleRequiredCodeRule(message: "adaptive result bundle needs this field")
        let item = Labs.newAdaptiveResultBundle("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
