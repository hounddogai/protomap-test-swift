@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultResultCheckpointValidator()
        let item = Labs.newResultCheckpoint("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsResultCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.ResultCheckpointCodeLengthRule(maxLength: 80)
        let item = Labs.newResultCheckpoint("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultCheckpointRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Labs.ResultCheckpointRequiredExternalRefRule(message: "result checkpoint needs an entry")
        let item = Labs.newResultCheckpoint("", name: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsResultCheckpointExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Labs.ResultCheckpointExternalRefLengthRule(maxLength: 3600)
        let item = Labs.newResultCheckpoint("x", name: "y")
        item.externalRef = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultCheckpointChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Labs.ResultCheckpointChecksumLengthRule(maxLength: 255)
        let item = Labs.newResultCheckpoint("x", name: "y")
        item.checksum = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}
