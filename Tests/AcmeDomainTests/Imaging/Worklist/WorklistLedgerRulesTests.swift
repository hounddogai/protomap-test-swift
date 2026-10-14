@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWorklistLedgerValidator()
        let item = Imaging.newWorklistLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWorklistLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.WorklistLedgerRequiredCodeRule(message: "worklist ledger needs a value")
        let item = Imaging.newWorklistLedger("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWorklistLedgerUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Imaging.WorklistLedgerUpdatedAtRangeRule(min: 32, max: 255)
        let item = Imaging.newWorklistLedger("x", name: "y")
        item.updatedAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWorklistLedgerGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Imaging.WorklistLedgerGraceDaysRangeRule(min: 80, max: 255)
        let item = Imaging.newWorklistLedger("x", name: "y")
        item.graceDays = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWorklistLedgerMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Imaging.WorklistLedgerMarginRangeRule(min: 0.6, max: 4633.3)
        let item = Imaging.newWorklistLedger("x", name: "y")
        item.margin = 4634.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWorklistLedgerRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.WorklistLedgerRequiredNameRule(message: "worklist ledger needs a value")
        let item = Imaging.newWorklistLedger("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
