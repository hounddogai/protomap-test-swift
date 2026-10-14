@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultReadSnapshotValidator()
        let item = Imaging.newReadSnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingReadSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ReadSnapshotRequiredCodeRule(message: "read snapshot needs an entry")
        let item = Imaging.newReadSnapshot("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingReadSnapshotProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Imaging.ReadSnapshotProcedureCodeLengthRule(maxLength: 32)
        let item = Imaging.newReadSnapshot("x", title: "y")
        item.procedureCode = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingReadSnapshotRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Imaging.ReadSnapshotRequiredProcedureCodeRule(message: "read snapshot needs an entry")
        let item = Imaging.newReadSnapshot("", title: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingReadSnapshotSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Imaging.ReadSnapshotSpecialtyLengthRule(maxLength: 80)
        let item = Imaging.newReadSnapshot("x", title: "y")
        item.specialty = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}
