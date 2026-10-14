@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCensusRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CensusRequestStore = BedManagement.newMemoryCensusRequestStore()
        let item = BedManagement.newCensusRequest("code-132", label: "label-411")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
