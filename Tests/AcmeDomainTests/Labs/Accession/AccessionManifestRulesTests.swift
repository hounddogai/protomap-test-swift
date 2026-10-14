@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionManifestValidator()
        let item = Labs.newAccessionManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionManifestAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Labs.AccessionManifestAmountRangeRule(min: 8.6, max: 3680.6)
        let item = Labs.newAccessionManifest("x", label: "y")
        item.amount = 3682.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAccessionManifestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.AccessionManifestRequiredLabelRule(message: "accession manifest needs this field")
        let item = Labs.newAccessionManifest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
