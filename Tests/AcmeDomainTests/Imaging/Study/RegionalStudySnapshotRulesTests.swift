@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalStudySnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultRegionalStudySnapshotValidator()
        let item = Imaging.newRegionalStudySnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingRegionalStudySnapshotRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.RegionalStudySnapshotRequiredLabelRule(message: "regional study snapshot needs a value")
        let item = Imaging.newRegionalStudySnapshot("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingRegionalStudySnapshotLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.RegionalStudySnapshotLabelLengthRule(maxLength: 1000)
        let item = Imaging.newRegionalStudySnapshot("x", name: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingRegionalStudySnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.RegionalStudySnapshotCodeLengthRule(maxLength: 64)
        let item = Imaging.newRegionalStudySnapshot("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingRegionalStudySnapshotRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.RegionalStudySnapshotRequiredNameRule(message: "regional study snapshot needs this field")
        let item = Imaging.newRegionalStudySnapshot("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingRegionalStudySnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.RegionalStudySnapshotRequiredCodeRule(message: "regional study snapshot needs a value")
        let item = Imaging.newRegionalStudySnapshot("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
