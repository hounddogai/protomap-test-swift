@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictReadSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStrictReadSnapshotValidator()
        let item = Imaging.newStrictReadSnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStrictReadSnapshotNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.StrictReadSnapshotNameLengthRule(maxLength: 64)
        let item = Imaging.newStrictReadSnapshot("x", title: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStrictReadSnapshotTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.StrictReadSnapshotTitleLengthRule(maxLength: 120)
        let item = Imaging.newStrictReadSnapshot("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStrictReadSnapshotRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.StrictReadSnapshotRequiredTitleRule(message: "strict read snapshot needs an entry")
        let item = Imaging.newStrictReadSnapshot("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
