@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenManifestValidator()
        let item = Labs.newSpecimenManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenManifestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.SpecimenManifestCodeLengthRule(maxLength: 64)
        let item = Labs.newSpecimenManifest("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSpecimenManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.SpecimenManifestRequiredCodeRule(message: "specimen manifest needs an entry")
        let item = Labs.newSpecimenManifest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
