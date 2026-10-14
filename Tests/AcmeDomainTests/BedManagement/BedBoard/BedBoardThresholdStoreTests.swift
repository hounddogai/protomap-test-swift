@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryBedBoardThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.BedBoardThresholdStore = BedManagement.newMemoryBedBoardThresholdStore()
        let item = BedManagement.newBedBoardThreshold("code-874", title: "title-928")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
