@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCensusGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CensusGroupStore = BedManagement.newMemoryCensusGroupStore()
        let item = BedManagement.newCensusGroup("code-542", title: "title-286")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
