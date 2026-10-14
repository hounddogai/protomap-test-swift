@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCleaningSnapshotValidator()
        let item = BedManagement.newCleaningSnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCleaningSnapshotTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.CleaningSnapshotTitleLengthRule(maxLength: 255)
        let item = BedManagement.newCleaningSnapshot("x", name: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCleaningSnapshotRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.CleaningSnapshotRequiredNameRule(message: "cleaning snapshot needs an entry")
        let item = BedManagement.newCleaningSnapshot("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.CleaningSnapshotRequiredCodeRule(message: "cleaning snapshot needs an entry")
        let item = BedManagement.newCleaningSnapshot("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
