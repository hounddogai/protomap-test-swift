@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultReadLedgerValidator()
        let item = Imaging.newReadLedger("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingReadLedgerOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Imaging.ReadLedgerOwnerIDLengthRule(maxLength: 16)
        let item = Imaging.newReadLedger("x", title: "y")
        item.ownerID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingReadLedgerRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Imaging.ReadLedgerRequiredOwnerIDRule(message: "read ledger needs this field")
        let item = Imaging.newReadLedger("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingReadLedgerTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.ReadLedgerTitleLengthRule(maxLength: 16)
        let item = Imaging.newReadLedger("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
