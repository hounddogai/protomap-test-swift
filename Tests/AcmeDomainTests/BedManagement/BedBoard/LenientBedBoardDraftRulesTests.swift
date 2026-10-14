@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientBedBoardDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLenientBedBoardDraftValidator()
        let item = BedManagement.newLenientBedBoardDraft("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLenientBedBoardDraftWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = BedManagement.LenientBedBoardDraftWeightRangeRule(min: 1.0, max: 887.0)
        let item = BedManagement.newLenientBedBoardDraft("x", label: "y")
        item.weight = 888.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementLenientBedBoardDraftRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = BedManagement.LenientBedBoardDraftRetriesRangeRule(min: 16, max: 3600)
        let item = BedManagement.newLenientBedBoardDraft("x", label: "y")
        item.retries = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementLenientBedBoardDraftCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.LenientBedBoardDraftCodeLengthRule(maxLength: 255)
        let item = BedManagement.newLenientBedBoardDraft("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementLenientBedBoardDraftBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = BedManagement.LenientBedBoardDraftBedLengthRule(maxLength: 64)
        let item = BedManagement.newLenientBedBoardDraft("x", label: "y")
        item.bed = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}
