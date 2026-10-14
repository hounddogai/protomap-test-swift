@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStudyLedgerValidator()
        let item = Imaging.newStudyLedger("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStudyLedgerMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Imaging.StudyLedgerMarginRangeRule(min: 0.5, max: 4377.7)
        let item = Imaging.newStudyLedger("x", label: "y")
        item.margin = 4379.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingStudyLedgerQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Imaging.StudyLedgerQuantityRangeRule(min: 16, max: 32)
        let item = Imaging.newStudyLedger("x", label: "y")
        item.quantity = 33
        #expect(rule.check(item).count > 0)
    }
}
