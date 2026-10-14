@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryFallbackCensusAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.FallbackCensusAdjustmentStore = BedManagement.newMemoryFallbackCensusAdjustmentStore()
        let item = BedManagement.newFallbackCensusAdjustment("code-999", name: "name-764")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
