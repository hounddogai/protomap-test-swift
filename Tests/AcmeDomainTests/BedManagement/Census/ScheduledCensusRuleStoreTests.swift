@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryScheduledCensusRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.ScheduledCensusRuleStore = BedManagement.newMemoryScheduledCensusRuleStore()
        let item = BedManagement.newScheduledCensusRule("code-924", title: "title-130")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
