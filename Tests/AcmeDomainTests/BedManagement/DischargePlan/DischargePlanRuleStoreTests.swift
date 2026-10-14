@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryDischargePlanRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.DischargePlanRuleStore = BedManagement.newMemoryDischargePlanRuleStore()
        let item = BedManagement.newDischargePlanRule("code-436", title: "title-259")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
