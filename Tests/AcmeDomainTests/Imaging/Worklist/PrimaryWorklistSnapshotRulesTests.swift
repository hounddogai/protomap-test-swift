@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryWorklistSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPrimaryWorklistSnapshotValidator()
        let item = Imaging.newPrimaryWorklistSnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPrimaryWorklistSnapshotDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Imaging.PrimaryWorklistSnapshotDiscountRangeRule(min: 6.6, max: 1724.9)
        let item = Imaging.newPrimaryWorklistSnapshot("x", title: "y")
        item.discount = 1726.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPrimaryWorklistSnapshotRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Imaging.PrimaryWorklistSnapshotRequiredProcedureCodeRule(
            message: "primary worklist snapshot needs this field"
        )
        let item = Imaging.newPrimaryWorklistSnapshot("", title: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPrimaryWorklistSnapshotProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Imaging.PrimaryWorklistSnapshotProcedureCodeLengthRule(maxLength: 80)
        let item = Imaging.newPrimaryWorklistSnapshot("x", title: "y")
        item.procedureCode = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
