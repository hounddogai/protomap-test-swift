@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryOvertimeRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.OvertimeRuleStore = Staffing.newMemoryOvertimeRuleStore()
        let item = Staffing.newOvertimeRule("code-709", label: "label-433")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
