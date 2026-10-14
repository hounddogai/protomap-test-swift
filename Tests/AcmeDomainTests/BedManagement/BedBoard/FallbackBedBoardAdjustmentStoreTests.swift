@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryFallbackBedBoardAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.FallbackBedBoardAdjustmentStore = BedManagement.newMemoryFallbackBedBoardAdjustmentStore()
        let item = BedManagement.newFallbackBedBoardAdjustment("code-490", label: "label-475")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
