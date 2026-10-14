@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryScheduledBedBoardTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.ScheduledBedBoardTargetStore = BedManagement.newMemoryScheduledBedBoardTargetStore()
        let item = BedManagement.newScheduledBedBoardTarget("code-271", label: "label-970")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
