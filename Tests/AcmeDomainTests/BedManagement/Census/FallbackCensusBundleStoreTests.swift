@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryFallbackCensusBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.FallbackCensusBundleStore = BedManagement.newMemoryFallbackCensusBundleStore()
        let item = BedManagement.newFallbackCensusBundle("code-209", name: "name-718")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
