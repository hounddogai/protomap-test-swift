@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFallbackFloatPoolCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FallbackFloatPoolCheckpointStore = Staffing.newMemoryFallbackFloatPoolCheckpointStore()
        let item = Staffing.newFallbackFloatPoolCheckpoint("code-856", label: "label-390")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
