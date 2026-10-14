@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryFallbackCensusSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.FallbackCensusSnapshotStore = BedManagement.newMemoryFallbackCensusSnapshotStore()
        let item = BedManagement.newFallbackCensusSnapshot("code-65", name: "name-907")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
