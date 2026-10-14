@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryLegacyCensusTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.LegacyCensusTierStore = BedManagement.newMemoryLegacyCensusTierStore()
        let item = BedManagement.newLegacyCensusTier("code-742", label: "label-29")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
