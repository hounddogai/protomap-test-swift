@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryAdaptiveCensusDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.AdaptiveCensusDraftStore = BedManagement.newMemoryAdaptiveCensusDraftStore()
        let item = BedManagement.newAdaptiveCensusDraft("code-151", label: "label-436")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
