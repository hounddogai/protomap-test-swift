@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCleaningRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CleaningRuleStore = BedManagement.newMemoryCleaningRuleStore()
        let item = BedManagement.newCleaningRule("code-305", name: "name-894")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
