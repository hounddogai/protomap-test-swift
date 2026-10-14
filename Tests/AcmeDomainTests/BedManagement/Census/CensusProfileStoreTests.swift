@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCensusProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CensusProfileStore = BedManagement.newMemoryCensusProfileStore()
        let item = BedManagement.newCensusProfile("code-36", title: "title-382")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
