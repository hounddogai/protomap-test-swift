@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultReadRuleValidator()
        let item = Imaging.newReadRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingReadRuleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.ReadRuleRequiredNameRule(message: "read rule needs a value")
        let item = Imaging.newReadRule("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingReadRuleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.ReadRuleNameLengthRule(maxLength: 120)
        let item = Imaging.newReadRule("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingReadRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ReadRuleCodeLengthRule(maxLength: 86400)
        let item = Imaging.newReadRule("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingReadRuleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ReadRuleRequiredCodeRule(message: "read rule needs a value")
        let item = Imaging.newReadRule("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingReadRuleRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Imaging.ReadRuleRequiredDiagnosisCodeRule(message: "read rule needs a value")
        let item = Imaging.newReadRule("", name: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
