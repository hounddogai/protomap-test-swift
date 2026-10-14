@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryFallbackBedBoardVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.FallbackBedBoardVarianceStore = BedManagement.newMemoryFallbackBedBoardVarianceStore()
        let item = BedManagement.newFallbackBedBoardVariance("code-547", name: "name-566")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
