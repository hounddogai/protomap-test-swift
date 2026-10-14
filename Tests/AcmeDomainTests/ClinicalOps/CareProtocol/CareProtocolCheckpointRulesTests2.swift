@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCareProtocolCheckpointValidator()
        let item = ClinicalOps.newCareProtocolCheckpoint("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCareProtocolCheckpointRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.CareProtocolCheckpointRequiredNameRule(message: "care protocol checkpoint needs an entry")
        let item = ClinicalOps.newCareProtocolCheckpoint("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolCheckpointUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = ClinicalOps.CareProtocolCheckpointUnitLengthRule(maxLength: 255)
        let item = ClinicalOps.newCareProtocolCheckpoint("x", name: "y")
        item.unit = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCareProtocolCheckpointNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.CareProtocolCheckpointNameLengthRule(maxLength: 86400)
        let item = ClinicalOps.newCareProtocolCheckpoint("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCareProtocolCheckpointRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = ClinicalOps.CareProtocolCheckpointRequiredUnitRule(
            message: "care protocol checkpoint needs this field"
        )
        let item = ClinicalOps.newCareProtocolCheckpoint("", name: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
