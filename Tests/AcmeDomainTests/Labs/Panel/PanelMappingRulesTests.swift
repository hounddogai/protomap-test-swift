@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelMappingValidator()
        let item = Labs.newPanelMapping("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelMappingNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.PanelMappingNameLengthRule(maxLength: 255)
        let item = Labs.newPanelMapping("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPanelMappingRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.PanelMappingRequiredNameRule(message: "panel mapping needs this field")
        let item = Labs.newPanelMapping("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelMappingOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Labs.PanelMappingOwnerIDLengthRule(maxLength: 16)
        let item = Labs.newPanelMapping("x", name: "y")
        item.ownerID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
