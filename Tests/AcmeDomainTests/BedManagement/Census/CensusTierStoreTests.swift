@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCensusTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CensusTierStore = BedManagement.newMemoryCensusTierStore()
        let item = BedManagement.newCensusTier("code-995", name: "name-41")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
