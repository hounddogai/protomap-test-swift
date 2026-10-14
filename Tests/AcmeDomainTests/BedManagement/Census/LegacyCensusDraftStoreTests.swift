@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryLegacyCensusDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.LegacyCensusDraftStore = BedManagement.newMemoryLegacyCensusDraftStore()
        let item = BedManagement.newLegacyCensusDraft("code-817", label: "label-298")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
