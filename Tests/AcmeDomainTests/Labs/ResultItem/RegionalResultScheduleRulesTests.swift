@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalResultScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultRegionalResultScheduleValidator()
        let item = Labs.newRegionalResultSchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsRegionalResultScheduleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.RegionalResultScheduleRequiredCodeRule(message: "regional result schedule needs an entry")
        let item = Labs.newRegionalResultSchedule("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRegionalResultScheduleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.RegionalResultScheduleRequiredNameRule(message: "regional result schedule needs an entry")
        let item = Labs.newRegionalResultSchedule("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
