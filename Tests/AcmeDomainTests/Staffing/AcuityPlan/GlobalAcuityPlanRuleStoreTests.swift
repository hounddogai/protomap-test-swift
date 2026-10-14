@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryGlobalAcuityPlanRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.GlobalAcuityPlanRuleStore = Staffing.newMemoryGlobalAcuityPlanRuleStore()
        let item = Staffing.newGlobalAcuityPlanRule("code-838", title: "title-776")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
